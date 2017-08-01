class TransportFee < ActiveRecord::Base
  belongs_to :employee

  validates :month, uniqueness: { scope: [:month, :employee_id] }

  COLUMNS = %w(employee_id month employee_no channel_id employee_name department_name position_name amount total add_garnishee notes remark is_continue_vacation)

  class << self
    def compute(month)
      prev_month = Date.parse(month + "-01").prev_month.strftime("%Y-%m")

      is_success, messages = AttendanceSummary.can_calc_salary?(prev_month)
      return [is_success, messages] unless is_success

      # 先全部删除计算记录
      @remark_hash = TransportFee.where(month: month).index_by(&:employee_id)

      t1 = Time.new

      TransportFee.transaction do
        @values = []
        @calc_values = []

        Employee.includes(:special_states, :salary_person_setup, :channel, :department, :master_positions, :labor_relation, :hours_fees, :transport_fees).find_in_batches(batch_size: 3000).with_index do |group, batch|
          puts "+-----------第 #{batch} 批 -----------+"
          group.each do |employee|
            next unless employee.salary_person_setup
            next if employee.salary_person_setup.try(:is_special_category)
            # next if employee.is_service_a?

            # raise "#{employee.name} 缺少薪酬设置" if !employee.salary_person_setup

            # 1. 地面岗位 600，空勤通道 1100，飞行员 1200
            # 2. 一副级以上飞行员 and 空勤通道的干部 600
            # 3. 副总师，总助（级）以上的级别无交通费
            # 4. 飞行员在飞行学员队，交通费为 600，下队后 1200，除非第一个工作日下队

            # 5. 全月不在岗扣完, 15天(包含休息日)以上不在岗扣 50%, 15天(包含休息日)以下（含）不扣，两个月累计不清零超过15天(包含休息日)以上，也扣 50%，扣在后面那个月
            # 6. TODO 空勤岗至地面岗位处理，从次月起按地面岗位发放交通费
            # 7. 要扣除班车费用，全月未上班，忽略班车费扣除
            # 8. 停薪调状态，停发交通费
            fee = 0
            hash = {employee_id: employee.id, category: 'transport_fee', month: month}
            calc_step = CalcStep.new(hash)
            @standard = 0

            special_states = employee.special_states.select{|s| s.special_category == "空勤停飞"}

            if !employee.salary_person_setup.is_send_transport_fee
              calc_step.push_step('薪酬个人设置不发放交通费')
              fee = 0
            # elsif employee.is_trainee?
            #   calc_step.push_step('实习生交通费为 0')
            #   fee = 0
            elsif employee.is_stop_salary
              calc_step.push_step('处于停薪调状态，初始化交通费 0')
              fee = 0
            elsif employee.is_fly_channel? && SpecialState.personal_stop_fly_months(special_states, prev_month) > 5
              calc_step.push_step('因个人原因空勤停飞的第 6 个月仅有基本工资，交通费为 0，并且不扣除班车费')
              fee = 0
              @stop_fly_six_month = true
            elsif %w(公司正职 公司副职 总师/总监).include?(employee.duty_rank.try(:display_name))
              calc_step.push_step('总助职(不含)以上的没有交通费, 初始化金额 0')
              fee = 0
            else
              if employee.is_fly_channel?
                calc_step.push_step('属于飞行通道')
                @standard = 1200

                if %w(总助职 分公司级 一正 一正级 一副 一副级).include?(employee.duty_rank.try(:display_name))
                  calc_step.push_step('一副级(含)以上, 总助职(含)以下初始化金额 600')
                  @standard = fee = 600
                elsif employee.is_flyer_student_channel?
                  calc_step.push_step('飞行学员初始化金额 600')
                  @standard = fee = 600
                elsif employee.leave_flyer_student_date && Date.parse(month + "-01").month == employee.leave_flyer_student_date.month
                  # 计算薪酬的月份和下队的月份相同
                  calc_step.push_step('不是飞行学员，下队时间 ' + employee.leave_flyer_student_date.strftime("%Y-%m-%d"))

                  # 当月的第一天上班的日期
                  @first_working_date = VacationRecord.first_working_date(month)
                  calc_step.push_step("月份 #{month} 第1天上班日期是 #{@first_working_date}")

                  if employee.leave_flyer_student_date.day != @first_working_date
                    calc_step.push_step('下队时间不是当月第1天上班，初始化金额 600')
                    fee = 600
                  else
                    calc_step.push_step('下队时间是当月第1天上班，初始化金额 1200')
                    fee = 1200
                  end
                elsif employee.hours_fees.select{|h| h.month == prev_month && h.is_not_fly_sky}.size > 0
                  calc_step.push_step('没有飞行时间，只有模拟机带教，按照地面人员发放 600')
                  fee = 600
                else
                  calc_step.push_step('下队时间系统未知') if !employee.leave_flyer_student_date
                  calc_step.push_step('初始化金额 1200')
                  fee = 1200
                end
              elsif employee.is_air_service_channel?
                # TODO 需要看从空勤通道到非空勤通道的时间，第6条规则
                calc_step.push_step('属于空勤通道')

                # 是否空勤转地面工作的时限内(派驻->空勤停飞->空勤地面)
                if employee.is_stop_fly_to_land?(month)
                  calc_step.push_step('处于空勤转地面状态，缴费费按地面岗位标准，初始化金额 600')
                  @standard = fee = 600
                elsif (employee.is_category_leader? || employee.is_category_super_leader?) && %w(二正 二正级 二副 二副级 无).exclude?(employee.duty_rank.try(:display_name))
                  calc_step.push_step('是干部或者领导, 并且职务职级在二正级(不含)以上，初始化金额 600')
                  @standard = fee = 600
                else
                  calc_step.push_step('不是干部或领导，并且职务职级在二正级(含)以下, 初始化金额 1100')
                  @standard = fee = 1100
                end
              else
                calc_step.push_step('不是飞行和空勤通道，初始化交通费 600')
                @standard = fee = 600
              end
            end

            prev_transport_fee = employee.transport_fees.select{|b| b.month == prev_month}.first
            is_continue_vacation = false

            # 是否全月不在岗
            if employee.full_month_vacation?(prev_month)
              calc_step.push_step("全月 #{prev_month} 不在岗，交通费补助为 0")
              fee = 0
            elsif employee.get_vacation_days(prev_month) > 15 || (employee.is_continue_vacation_days?(prev_month, 15) && !prev_transport_fee.try(:is_continue_vacation))
              calc_step.push_step("累计不清零请假的最大天数大于 15 天，交通费减半")
              fee = fee * 0.5
              is_continue_vacation = true
            end


            #is_in_month = special_states.select{|special| special.is_in_month?(prev_month)}.size
            ground_days = SpecialState.in_month_special_days(special_states, prev_month, "空勤停飞")
            vacation_days = employee.get_vacation_days(prev_month)
            attendance_days = employee.attendances.where(record_date: "#{prev_month}-01".to_date.."#{prev_month}-01".to_date.end_of_month).size

            fly_hours = employee.hours_fees.select{|h| h.month == prev_month}.map(&:fly_hours).map(&:to_f).inject(:+).to_f            
            # if fly_hours == 0 && is_in_month
            if fly_hours == 0 && (ground_days + vacation_days + attendance_days) >= 15
              # calc_step.push_step("全月 #{prev_month} 未飞，并且异动表有空勤停飞的数据，交通费补助为 0")
              calc_step.push_step("全月 #{prev_month} 未飞，并且空勤停飞+请假天数+迟到早退大于等于15天，交通费补助为 0")
              fee = 0
            end

            if employee.join_scal_date && employee.join_scal_date.strftime("%Y-%m") == prev_month && prev_transport_fee.blank?
              if employee.join_scal_date.day >= 15
                fee += @standard*0.5
                calc_step.push_step("补发上月交通费: #{@standard*0.5}")
              else
                fee += @standard
                calc_step.push_step("补发上月交通费: #{@standard}")
              end
            end

            # @total = fee + @remark_hash[employee.id].try(:add_garnishee).to_f
            @total = fee
            calc_step.push_step("交通费总和 #{@total}")
            calc_step.final_amount(@total)

            @notes = employee.get_vacation_desc(prev_month).try(:values).try(:join, ", ").to_s
            @values << [employee.id, month, employee.employee_no, employee.channel_id, employee.name, employee.department.full_name, employee.master_position.name, fee, @total, @remark_hash[employee.id].try(:add_garnishee).to_f, @notes, @remark_hash[employee.id].try(:remark), is_continue_vacation]
            @calc_values << [calc_step.employee_id, calc_step.month, calc_step.category, calc_step.step_notes, calc_step.amount]
          end
        end

        TransportFee.where(month: month).delete_all
        CalcStep.remove_items('transport_fee', month)

        CalcStep.import(CalcStep::COLUMNS, @calc_values, validate: false)
        TransportFee.import(COLUMNS, @values, validate: false)

        @calc_values.clear
        @values.clear
      end

      t2 = Time.new
      puts "计算耗费 #{t2 - t1} 秒"

      return true
    end
  end
end

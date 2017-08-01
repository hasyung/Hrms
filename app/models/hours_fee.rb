class HoursFee < ActiveRecord::Base
  belongs_to :employee

  IMPORTOR_TYPE = {
    "飞行员小时费合计表" => :import_fly_fee,
    "乘务员小时费合计表" => :import_service_fee,
    "安全员小时费合计表" => :import_security_fee,
    "上浮名单" => :import_service_upper,
    "下靠名单" => :import_service_lower,
    "兼职补贴" => :import_service_land_work,
    "空勤精编奖励" => :import_delicacy_reward
  }

  CATEGORIES = {
    '飞行员' => 'hours_fee/flyer',
    '乘务员' => 'hours_fee/service',
    '安全员' => 'hours_fee/security'
  }

  COLUMNS = %w(
  employee_no employee_name department_name position_name month
  channel_id employee_id fly_hours fly_fee airline_fee reality_fly_hours
  total_hours_fee total_security_fee hours_fee_difference refund_fee
  up_or_down up_or_down_money performance_revenue fertility_allowance
  ground_subsidy hours_fee_category total add_garnishee notes
  salary_set_book remark is_not_fly_sky is_land_work land_work_money
  refund_fee_remain delicacy_reward demo_fly_money is_deduct_absenteeism
  )

  AIRLINE_COLUMNS = %w(
  employee_id employee_no employee_name department_name position_name month
  airline_fee oversea_food_fee add_garnishee remark note total_fee hours_fee_category
  )

  SECURITY_COLUMNS = %w(
  employee_id employee_no employee_name department_name position_name month
  fee add_garnishee total remark notes
  )

  before_save :update_info, if: -> (info) { info.employee_id_changed? }

  validates :month, uniqueness: { scope: [:month, :employee_id, :hours_fee_category] }

  def self.compute(month, hours_fee_category)
    HoursFee.transaction do
      is_success, messages = AttendanceSummary.can_calc_salary?(month)
      return [is_success, messages] unless is_success

      if hours_fee_category == '飞行员'
        compute_flyer(month, hours_fee_category)
      elsif hours_fee_category == '乘务员'
        compute_service(month, hours_fee_category)
      elsif hours_fee_category == '安全员'
        compute_security(month, hours_fee_category)
      else
        return false
      end
    end
  end

  private
  def update_info
    self.employee_no     = self.employee.employee_no
    self.employee_name   = self.employee.name
    self.department_name = self.employee.department.full_name
    self.position_name   = self.employee.master_position.name
    self.channel_id      = self.employee.channel_id
  end

  class << self
    def compute_flyer(month, hours_fee_category)
      hours_fees = HoursFee.joins(:employee).includes(employee: [:salary_person_setup, :punishments, :special_states,
        :attendance_summaries, :hours_fees, :channel, :category]).where("hours_fees.hours_fee_category = '#{hours_fee_category}'
        and hours_fees.month = '#{month}'")
      teachers = hours_fees.select{|h| %w(teacher_A teacher_B).include?(h.employee.try(:salary_person_setup).try(:fly_hour_fee))}
        .sort{|x, y| x.total_hours_fee.to_f + x.total_security_fee.to_f <=> y.total_hours_fee.to_f + y.total_security_fee.to_f}
        .last(10)
    #  average_hours_fees = teachers.present? ? (teachers.inject(0){|c, t|c += t.total_hours_fee.to_f}/teachers.size).round(2) : 0
    #  average_security_fees = teachers.present? ? (teachers.inject(0){|c, t|c += t.total_security_fee.to_f}/teachers.size).round(2) : 0
    ## 进行四舍五入
      average_hours_fees = teachers.present? ? (teachers.inject(0){|c, t|c += t.total_hours_fee.to_f}/teachers.size).round : 0
      average_security_fees = teachers.present? ? (teachers.inject(0){|c, t|c += t.total_security_fee.to_f}/teachers.size).round : 0


      fly_attendant_hour = Salary.find_by(category: 'flyer_hour').form_data
      global = Salary.find_by(category: 'global').form_data
      global_council = global["coefficient"][month]
      global_council ||= {}
      start_month = (month + '-01').to_date.beginning_of_month
      end_month = (month + '-01').to_date.end_of_month
      next_month = (month + '-01').to_date.next_month.strftime("%Y-%m")
      values, calc_values, airline_values, security_values = [], [], [], []

      hours_fees.each do |hours_fee|
        setup = hours_fee.employee.salary_person_setup
        next if hours_fee.employee.channel.try(:display_name) != '飞行' || ['', '无'].include?(setup.try(:fly_hour_fee))
        return [false, "#{hours_fee.employee.name}  #{hours_fee.employee.employee_no}缺少个人薪酬设置或小时费设置错误"] if setup.blank? || fly_attendant_hour[setup.fly_hour_fee].blank?

        hours_fee.notes = ''
        summary = hours_fee.employee.attendance_summaries.select{|s| s.summary_date == month}.first

        is_land_work = hours_fee.employee.special_states.select{|s| (s.special_category == '空勤地面' || 
          s.special_category == '借调') &&
          ((s.special_date_from < start_month && (s.special_date_to.blank? || s.special_date_to >
          end_month)) || (s.special_date_from >= start_month && s.special_date_from <= end_month) ||
          (s.special_date_to && s.special_date_to >= start_month && s.special_date_to <= end_month))
          }.present?
        is_full_land_work = hours_fee.employee.special_states.select{|s| (s.special_category == '空勤地面' || 
          s.special_category == '借调') &&
          (s.special_date_from <= start_month && (s.special_date_to.blank? || s.special_date_to >=
          end_month))}.present?
        salary = hours_fee.employee.performance_salaries.select{|p| p.month == month}.first
        department_fee = (salary.try(:department_distribute).to_f*global_council["perf_execute"].to_f + salary.try(:department_reserved).to_f).round(2)
        department_fee = salary.try(:base_salary).to_f if department_fee == 0

        calc_step = CalcStep.new employee_id: hours_fee.employee_id, month: month, category: 'hours_fee/flyer'
        security_calc_step = CalcStep.new employee_id: hours_fee.employee_id, month: month, category: 'security_fee'
        security_fee = SecurityFee.new employee_id: hours_fee.employee_id, month: month

        hours_fee.fly_fee = hours_fee.total_hours_fee.to_f
        security_fee.fee = hours_fee.total_security_fee.to_f
        calc_step.push_step("#{calc_step.step_notes.size + 1}. 导入小时费为：#{hours_fee.total_hours_fee}")
        security_calc_step.push_step("#{calc_step.step_notes.size + 1}. 导入安飞奖为: #{hours_fee.total_security_fee}")

        if setup.fly_hour_fee == 'observer' && (%w(领导 干部).include?(hours_fee.employee.category.try(:display_name)) || setup.technical_grade)
          if hours_fee.fly_hours.to_f > 20 && hours_fee.fly_fee < 16500
            hours_fee.fly_fee = 16500
            calc_step.push_step("#{calc_step.step_notes.size + 1}. 普通空中观察员，飞满20小时，实际飞行小时费低于16500的，小时费按16500发放")
          end
        end

        special_states = hours_fee.employee.special_states.select{|s| s.special_category == "空勤停飞"}
        stop_fly_months = SpecialState.personal_stop_fly_months(special_states, month)
        month_days = Date.parse(month + "-01").end_of_month.day

        refund_fee = hours_fee.refund_fee.to_f + get_refund_fee_remain(hours_fee.employee.hours_fees, month)
        punishment_type = excute_punishment(hours_fee, month, fly_attendant_hour, setup, calc_step, 0)
        hours_fee.hours_fee_difference = hours_fee.airline_fee = 0
        is_stop_fly = stop_fly_months >= 6 && hours_fee.demo_fly_money.to_f/fly_attendant_hour[setup.fly_hour_fee] == 0

        if is_stop_fly
          hours_fee.fly_fee = hours_fee.airline_fee = 0
          hours_fee.notes = '个人不参加体检，或体检合格但个人原因无故停飞6个月含以上'
          calc_step.push_step("#{calc_step.step_notes.size + 1}. 个人不参加体检，或体检合格但个人原因无故停飞6个月含以上的，不发放小时费、空勤灶和飞行驾驶技术津贴")
        else
          if punishment_type == 'all'
            hours_fee.fly_fee = 0
          elsif is_full_land_work
            hours_fee.fly_fee = department_fee
            calc_step.push_step("#{calc_step.step_notes.size + 1}. 整月空勤停飞上地面行政班, 当月小时费=部门考核性收入分配结果(#{salary.try(:department_distribute).to_f}" +
              ")*公司绩效系数(#{global_council["perf_execute"].to_f})+部门留存分配结果(#{salary.try(:department_reserved).to_f})")
          else
            if punishment_type.to_f > 0
              punishment_money = (punishment_type.to_f*hours_fee.fly_hours.to_f).round(2)
              calc_step.push_step("#{calc_step.step_notes.size + 1}. 飞行员处分扣款: 差额(#{punishment_type.to_f})*飞行时间(#{hours_fee.fly_hours.to_f})=#{punishment_money}")
              hours_fee.fly_fee -= punishment_money
            end

            if summary
              vacation_desc = hours_fee.employee.get_vacation_desc(month).try(:values).try(:join, ", ").to_s
              hours_fee.notes += ", " if hours_fee.notes.size > 0 && vacation_desc.size > 0
              hours_fee.notes += vacation_desc
            end

            if hours_fee.is_not_fly_sky && !HoursFee.is_still_not_fly_sky?(hours_fee.employee.hours_fees, month)
              hours_fee.hours_fee_difference = (30.0*fly_attendant_hour[setup.fly_hour_fee]).round(2)
              calc_step.push_step("#{calc_step.step_notes.size + 1}. 没有小时费，只有模拟机带教的飞行员享受小时费补贴: 30小时/月*#{fly_attendant_hour[setup.fly_hour_fee]} = #{hours_fee.hours_fee_difference}")
            elsif %w(领导 干部).include?(hours_fee.employee.category.try(:display_name)) || setup.technical_grade.present?
              demo_fly_hours = (hours_fee.demo_fly_money.to_f/fly_attendant_hour[setup.fly_hour_fee]).round(2)

              proportion1 = summary.try(:paid_leave).to_f > 0 ? (month_days - summary.try(:paid_leave).to_f)/month_days.to_f : 1
              proportion = hours_fee.reality_fly_hours.to_f + demo_fly_hours > setup.lower_limit_hour.to_f || (hours_fee.reality_fly_hours.to_f + demo_fly_hours > 0 &&
                setup.is_flyer_land_work) || setup.lower_limit_hour.to_f == 0 ? 1 : (hours_fee.reality_fly_hours.to_f + demo_fly_hours)/(setup.lower_limit_hour.to_f*proportion1)
              proportion = 1 if proportion > 1
              proportion = 0 if proportion1 == 0

              if %w(领导 干部).include?(hours_fee.employee.category.try(:display_name)) && setup.limit_leader
                hours_fee.hours_fee_difference = (average_hours_fees*proportion)
                security_fee.fee = (average_security_fees*proportion)
                hours_fee.fly_fee = 0
                calc_step.push_step("#{calc_step.step_notes.size + 1}. 飞行受限干部享受小时费补差, 最低飞行时间:" +
                  "#{setup.lower_limit_hour}, 本月带薪假合计:#{summary.try(:paid_leave).to_f}, 本月实际飞行时间:#{hours_fee.reality_fly_hours.to_f}, " +
                  "模拟机飞行时间:#{demo_fly_hours}, 教员机长综合小时费当月前十名小时费平均数:#{average_hours_fees} * 比例:" +
                  "(#{hours_fee.reality_fly_hours.to_f} + #{demo_fly_hours})/(#{setup.lower_limit_hour.to_f}*#{month_days - summary.try(:paid_leave).to_f}/#{month_days}) = #{hours_fee.hours_fee_difference}")
                security_calc_step.push_step("#{calc_step.step_notes.size + 1}. 飞行受限干部享受小时费补差, 最低飞行时间:" +
                  "#{setup.lower_limit_hour}, 本月带薪假合计:#{summary.try(:paid_leave).to_f}, 本月实际飞行时间:#{hours_fee.reality_fly_hours.to_f}, " +
                  "模拟机飞行时间:#{demo_fly_hours}, 教员机长综合小时费当月前十名小时费平均数:#{average_hours_fees} * 比例:" +
                  "(#{hours_fee.reality_fly_hours.to_f} + #{demo_fly_hours})/(#{setup.lower_limit_hour.to_f}*#{month_days - summary.try(:paid_leave).to_f}/#{month_days}) = #{security_fee.fee}")
              else
                hours_fee.hours_fee_difference = setup.leader_subsidy_hour.to_f*proportion.to_f*fly_attendant_hour[setup.fly_hour_fee].to_f

                step_note = "享受小时费补差, 干部岗位薪酬等级:#{setup.leader_grade}, " +
                  "最低飞行时间:#{setup.lower_limit_hour}, 本月带薪假合计:#{summary.try(:paid_leave).to_f}, 干部补贴飞行时间:#{setup.leader_subsidy_hour.to_f}*小时费标准:" +
                  "#{fly_attendant_hour[setup.fly_hour_fee]}*比例:"
                if proportion == 1
                  step_note += "1 = #{hours_fee.hours_fee_difference}"
                else
                  step_note += "(#{hours_fee.reality_fly_hours.to_f} + #{demo_fly_hours})/(#{setup.lower_limit_hour.to_f}*#{month_days - summary.try(:paid_leave).to_f}/#{month_days}) = #{hours_fee.hours_fee_difference}"
                end
                calc_step.push_step("#{calc_step.step_notes.size + 1}. " + step_note)
              end
            end
            hours_fee.fly_fee += hours_fee.hours_fee_difference

            if is_land_work
              if %w(领导 干部).include?(hours_fee.employee.category.try(:display_name)) or setup.technical_grade.present?
                if department_fee > hours_fee.fly_fee
                  calc_step.push_step("#{calc_step.step_notes.size + 1}. (部门考核性收入分配结果: #{salary.try(:department_distribute).to_f} * " +
                    "公司绩效系数: #{global_council["perf_execute"].to_f} + 部门留存分配结果: #{salary.try(:department_reserved).to_f})=" +
                    "#{department_fee} 大于 (实飞小时费+处分+干部补贴或前10名)=#{hours_fee.fly_fee}, 小时费=#{department_fee}")
                  hours_fee.fly_fee = department_fee
                else
                  calc_step.push_step("#{calc_step.step_notes.size + 1}. (部门考核性收入分配结果: #{salary.try(:department_distribute).to_f} * " +
                    "公司绩效系数: #{global_council["perf_execute"].to_f} + 部门留存分配结果: #{salary.try(:department_reserved).to_f})=" +
                    "#{department_fee} 不大于 (实飞小时费+处分+干部补贴或前10名)=#{hours_fee.fly_fee}, 小时费=#{hours_fee.fly_fee}")
                end
              else
                if department_fee > hours_fee.fly_fee
                  calc_step.push_step("#{calc_step.step_notes.size + 1}. (部门考核性收入分配结果: #{salary.try(:department_distribute).to_f} * " +
                    "公司绩效系数: #{global_council["perf_execute"].to_f} + 部门留存分配结果: #{salary.try(:department_reserved).to_f})=" +
                    "#{department_fee} 大于 (实飞小时费+处分+补贴)=#{hours_fee.fly_fee}, 小时费=#{department_fee}")
                  hours_fee.fly_fee = department_fee
                else
                  calc_step.push_step("#{calc_step.step_notes.size + 1}. (部门考核性收入分配结果: #{salary.try(:department_distribute).to_f} * " +
                    "公司绩效系数: #{global_council["perf_execute"].to_f} + 部门留存分配结果: #{salary.try(:department_reserved).to_f})=" +
                    "#{department_fee} 不大于 (实飞小时费+处分+补贴)=#{hours_fee.fly_fee}, 小时费=#{hours_fee.fly_fee}")
                end
              end
            end
          end
        end

        ### 时费补贴(生育津贴)
        hours_fee.fertility_allowance = 0
        # any_maternity_leave_days = summary.try(:maternity_leave).to_f + summary.try(:lactation_leave).to_f + summary.try(:injury_leave).to_f
        # if any_maternity_leave_days > 0
        #   proportion = any_maternity_leave_days/month_days.to_f
        #   hours_fee.fertility_allowance = (60.0*proportion*fly_attendant_hour[setup.fly_hour_fee]).round(2)
        #   calc_step.push_step("#{calc_step.step_notes.size + 1}. 请假类别为产假/哺乳假/工伤假，享受小时费补贴(生育津贴)：60小时/月*比例" +
        #     "(#{any_maternity_leave_days}/#{month_days})*小时费标准(#{fly_attendant_hour[setup.fly_hour_fee]}) = #{hours_fee.fertility_allowance}")
        # end

        # hours_fee.fly_fee += hours_fee.fertility_allowance

        ### 费用化报销
        fly_fee = 0
        note = "#{calc_step.step_notes.size + 1}. 当月小时费(#{hours_fee.fly_fee}) - 当月费用化报销合计(#{refund_fee}) = 小时费合计"
        if refund_fee > hours_fee.fly_fee.to_f
          refund_fee = refund_fee - hours_fee.fly_fee.to_f
        else
          fly_fee = (hours_fee.fly_fee.to_f - refund_fee).round(2)
          refund_fee = 0
        end
        calc_step.push_step(note + "(#{fly_fee})")
        hours_fee.fly_fee = fly_fee

        if hours_fee.fly_fee < 0
          hours_fee.fly_fee = 0
          calc_step.push_step("#{calc_step.step_notes.size + 1}. 如小时费小于 0, 则小时费最后为 0")
        end

        ### 空勤灶
        hours_fee.airline_fee = 0
        if setup.is_send_airline_fee && !is_stop_fly
          days = (next_month + '-01').to_date.end_of_month.day
          if hours_fee.employee.join_scal_date && hours_fee.employee.join_scal_date.strftime("%Y-%m") == next_month
            days -= hours_fee.employee.join_scal_date.day - 1
          end
          if setup.fly_hour_fee == 'student' && setup.flyer_student_train
            hours_fee.airline_fee = days * 15
            calc_step.push_step("#{calc_step.step_notes.size + 1}. 计算飞行员空勤灶, 学员队的飞行员:15 元/日, #{next_month}为:#{hours_fee.airline_fee}(不计入小时费最后金额)")
          else
            hours_fee.airline_fee = days * 30
            calc_step.push_step("#{calc_step.step_notes.size + 1}. 计算飞行员空勤灶, 30 元/日, #{next_month}为:#{hours_fee.airline_fee}(不计入小时费最后金额)")
          end
        end

        total = hours_fee.fly_fee
        setup.update(refund_fee: refund_fee) if refund_fee != setup.refund_fee.to_f

        values << [
          hours_fee.employee_no, hours_fee.employee_name,
          hours_fee.department_name, hours_fee.position_name, hours_fee.month,
          hours_fee.channel_id, hours_fee.employee_id, hours_fee.fly_hours,
          hours_fee.fly_fee, hours_fee.airline_fee, hours_fee.reality_fly_hours,
          hours_fee.total_hours_fee, hours_fee.total_security_fee,
          hours_fee.hours_fee_difference, hours_fee.refund_fee,
          hours_fee.up_or_down, hours_fee.up_or_down_money,
          hours_fee.performance_revenue, hours_fee.fertility_allowance,
          hours_fee.ground_subsidy, hours_fee.hours_fee_category, total,
          hours_fee.add_garnishee.to_f, hours_fee.notes,
          hours_fee.employee.salary_set_book, hours_fee.remark,
          hours_fee.is_not_fly_sky, hours_fee.is_land_work,
          hours_fee.land_work_money, refund_fee, hours_fee.delicacy_reward,
          hours_fee.demo_fly_money, hours_fee.is_deduct_absenteeism
        ]

        calc_values << [
          calc_step.employee_id, calc_step.month, calc_step.category,
          calc_step.step_notes, total
        ]

        calc_values << [
          security_calc_step.employee_id, security_calc_step.month, security_calc_step.category,
          security_calc_step.step_notes, security_fee.fee
        ]

        airline_values << [
          hours_fee.employee_id, hours_fee.employee_no, hours_fee.employee_name,
          hours_fee.department_name, hours_fee.position_name, hours_fee.month,
          hours_fee.airline_fee, nil, nil, nil, hours_fee.notes,
          hours_fee.airline_fee, '飞行员'
        ]

        security_values << [
          hours_fee.employee_id, hours_fee.employee_no, hours_fee.employee_name,
          hours_fee.department_name, hours_fee.position_name, hours_fee.month,
          security_fee.fee, nil, security_fee.fee, nil, hours_fee.notes
        ]
      end

      SecurityFee.where("month='#{month}' and employee_id in (?)", hours_fees.map(&:employee_id)).delete_all
      AirlineFee.where("month='#{month}' and (hours_fee_category='飞行员' or employee_id in (?))",
        hours_fees.map(&:employee_id)).delete_all
      CalcStep.where("month='#{month}' and (category='hours_fee/flyer' or category='security_fee')").delete_all
      hours_fees.delete_all

      CalcStep.import(CalcStep::COLUMNS, calc_values, validate: false)
      HoursFee.import(HoursFee::COLUMNS, values, validate: false)
      AirlineFee.import(HoursFee::AIRLINE_COLUMNS, airline_values, validate: false)
      SecurityFee.import(HoursFee::SECURITY_COLUMNS, security_values, validate: false)
    end

    def compute_service(month, hours_fee_category)
      hours_fees = HoursFee.joins(:employee).includes(employee: [:channel, :category, :salary_person_setup, :hours_fees, :punishments,
        :attendance_summaries, :performance_salaries, :special_states, :department]).where("hours_fees.hours_fee_category = '#{hours_fee_category}'
        and hours_fees.month = '#{month}'")
      fly_attendant_hour = Salary.find_by(category: 'fly_attendant_hour').form_data

      service_c_1_perf = Salary.find_by(category: 'service_c_1_perf')
      service_c_2_perf = Salary.find_by(category: 'service_c_2_perf')
      global = Salary.find_by(category: 'global').form_data
      global_council = global["coefficient"][month]
      global_council ||= {}
      values, calc_values, airline_values, other_employee_ids, employee_ids = [], [], [], [], []
      start_month = (month + '-01').to_date.beginning_of_month
      end_month = (month + '-01').to_date.end_of_month
      is_deduct_absenteeism = false

      hours_fees.each do |hours_fee|
        employee_ids << hours_fee.employee_id and next if employee_ids.include?(hours_fee.employee_id)
        employee_ids << hours_fee.employee_id
        setup = hours_fee.employee.salary_person_setup
        next if hours_fee.employee.channel.try(:display_name) != '空勤' || ['', '无'].include?(setup.try(:airline_hour_fee))
        return [false, "#{hours_fee.employee.name}  #{hours_fee.employee.employee_no}缺少个人薪酬设置或小时费设置错误"] if setup.blank? || fly_attendant_hour[setup.airline_hour_fee].blank?

        calc_step = CalcStep.new employee_id: hours_fee.employee_id, month: month, category: 'hours_fee/service'
        hours_fee.notes = ''

        hours_security = hours_fee.employee.hours_fees.select{|h| h.month == month && h.hours_fee_category == '安全员'}.first
        hours_fee.up_or_down_money = nil
        hours_fee.fly_fee = hours_fee.total_hours_fee.to_f + hours_fee.delicacy_reward.to_f
        calc_step.push_step("#{calc_step.step_notes.size + 1}. 本月空乘飞行时间为：#{hours_fee.fly_hours.to_f}，小时费 = " +
          "导入小时费(#{hours_fee.total_hours_fee.to_f}) + 空勤精编奖励(#{hours_fee.delicacy_reward.to_f})")

        summary = hours_fee.employee.attendance_summaries.select{|s| s.summary_date == month}.first

        is_land_work = hours_fee.employee.special_states.select{|s| (s.special_category == '空勤地面' || 
          s.special_category == '借调') &&
          ((s.special_date_from < start_month && (s.special_date_to.blank? || s.special_date_to >
          end_month)) || (s.special_date_from >= start_month && s.special_date_from <= end_month) ||
          (s.special_date_to && s.special_date_to >= start_month && s.special_date_to <= end_month))
          }.present?
        is_full_land_work = hours_fee.employee.special_states.select{|s| (s.special_category == '空勤地面' || 
          s.special_category == '借调') &&
          (s.special_date_from <= start_month && (s.special_date_to.blank? || s.special_date_to >=
          end_month))}.present?

        punishment_type = excute_punishment(hours_fee, month, fly_attendant_hour, setup, calc_step, 1)
        if punishment_type == 'all'
          hours_fee.fly_fee = 0
          other_employee_ids << hours_fee.employee_id if hours_security.blank?
        elsif hours_security
          hours_fee.fly_fee = 0
          calc_step.push_step("#{calc_step.step_notes.size + 1}. 双照安全员，小时费在安全员类别中计算，此处为0")
        else
          other_employee_ids << hours_fee.employee_id
          salary = hours_fee.employee.performance_salaries.select{|p| p.month == month}.first
          department_fee = (salary.try(:department_distribute).to_f*global_council["perf_execute"].to_f + salary.try(:department_reserved).to_f).round(2)
          department_fee = salary.try(:base_salary).to_f if department_fee == 0

          diff_year = hours_fee.employee.scal_working_years.to_i
          convert_standard = service_c_1_perf.get_amount_by_column('C', diff_year)
          if hours_fee.employee.join_scal_date.present? && convert_standard == 0
            diff_year = (Date.difference_in_months(end_month, hours_fee.employee.join_scal_date)/12.0).round(2)
            convert_standard = service_c_1_perf.get_amount_by_column('D', diff_year)
          end

          if is_full_land_work
            hours_fee.fly_fee = department_fee
            calc_step.push_step("#{calc_step.step_notes.size + 1}. 整月空勤停飞上地面行政班, 当月小时费=部门考核性收入分配结果(#{salary.try(:department_distribute).to_f}" +
              ")*公司绩效系数(#{global_council["perf_execute"].to_f})+部门留存分配结果(#{salary.try(:department_reserved).to_f})")
          else
            if punishment_type.to_f > 0
              punishment_money = (punishment_type.to_f*hours_fee.fly_hours.to_f).round(2)
              calc_step.push_step("#{calc_step.step_notes.size + 1}. 乘务员飞行处分扣款: 差额(#{punishment_type.to_f})*飞行时间(#{hours_fee.fly_hours.to_f})=#{punishment_money}")
              hours_fee.fly_fee -= punishment_money
            end

            if %w(领导 干部).include?(hours_fee.employee.category.try(:display_name)) || setup.technical_grade.present?
              month_days = Date.parse(month + "-01").end_of_month.day
              proportion1 = summary.try(:paid_leave).to_f > 0 ? (month_days - summary.try(:paid_leave).to_f)/month_days.to_f : 1
              proportion = hours_fee.fly_hours.to_f > setup.lower_limit_hour.to_f || (hours_fee.fly_hours.to_f > 0 &&
                setup.is_flyer_land_work) || setup.lower_limit_hour.to_f == 0 ? 1 : hours_fee.fly_hours.to_f/(setup.lower_limit_hour.to_f*proportion1)
              proportion = 1 if proportion > 1
              proportion = 0 if proportion1 == 0

              if is_land_work || %w(空保大队 客舱服务部).include?(hours_fee.employee.department.full_name.split('-').first)
                hours_fee.hours_fee_difference = setup.leader_subsidy_hour.to_f*proportion*fly_attendant_hour[setup.airline_hour_fee]
                step_note = "享受干部补贴, 干部岗位薪酬等级:#{setup.leader_grade}, " +
                  "最低飞行时间:#{setup.lower_limit_hour}, 本月带薪假合计:#{summary.try(:paid_leave).to_f}, 干部补贴飞行时间:#{setup.leader_subsidy_hour.to_f}*小时费标准:" +
                  "#{fly_attendant_hour[setup.airline_hour_fee]}*比例:"
                if proportion == 1
                  step_note += "1 = #{hours_fee.hours_fee_difference}"
                else
                  step_note += "#{hours_fee.fly_hours.to_f}/(#{setup.lower_limit_hour.to_f}*#{month_days - summary.try(:paid_leave).to_f}/#{month_days}) = #{hours_fee.hours_fee_difference}"
                end
                calc_step.push_step("#{calc_step.step_notes.size + 1}. " + step_note)
              else
                hours_fee.hours_fee_difference = department_fee * proportion
                step_note = "享受干部补贴, (部门考核性收入分配结果: #{salary.try(:department_distribute).to_f} * 公司绩效系数: " +
                  "#{global_council["perf_execute"].to_f} + 部门留存分配结果: #{salary.try(:department_reserved).to_f}) * 比例: "
                if proportion == 1
                  step_note += "1 = #{hours_fee.hours_fee_difference}"
                else
                  step_note += "#{hours_fee.fly_hours.to_f}/(#{setup.lower_limit_hour.to_f}*#{month_days - summary.try(:paid_leave).to_f}/#{month_days}) = #{hours_fee.hours_fee_difference}"
                end
                calc_step.push_step("#{calc_step.step_notes.size + 1}. " + step_note)
              end

              hours_fee.hours_fee_difference = 0 if hours_fee.hours_fee_difference.to_f <= 0
              hours_fee.fly_fee += hours_fee.hours_fee_difference
            end

            # 旷工
            year_summaries = hours_fee.employee.attendance_summaries.select{|s| (s.summary_date + '-01').to_date <= (month + '-01').to_date && (s.summary_date + '-01').to_date > (month + '-01').to_date.last_year}
            month_absenteeism_days = hours_fee.employee.attendance_summaries.where(summary_date:month).first.absenteeism.to_f
            year_absenteeism_days = 0
            hours_fee_months = []
            
            if month_absenteeism_days > 0
              year_summaries_month = year_summaries.map(&:summary_date)
              hours_fee_months = hours_fee.employee.hours_fees.select{|h| year_summaries_month.include?(h.month) && !h.is_deduct_absenteeism}.map(&:month)
              year_absenteeism_days = hours_fee.employee.attendance_summaries.select{|a| hours_fee_months.include?(a.summary_date)}.map(&:absenteeism).map(&:to_f).inject(:+).to_f
            elsif month_absenteeism_days == 0
              year_absenteeism_days = 0
              # hours_fee_months = Range.new((month + '-01').to_date.last_year.next_month, (month + '-01').to_date).to_a.map{|m| m.strftime("%Y-%m")}.uniq
              # month_hours_fee = hours_fee.employee.hours_fees.select{|h| hours_fee_months.include?(h.month) && h.is_deduct_absenteeism}
              # year_absenteeism_days = year_summaries.map(&:absenteeism).map(&:to_f).inject(&:+).to_f if month_hours_fee.blank?
            end
            if year_absenteeism_days > 0 && year_absenteeism_days < 2
              diff_year = hours_fee.employee.scal_working_years.to_i
              c2_amount = service_c_2_perf.get_amount_by_column('C', hours_fee.employee.scal_working_years.to_i)
              if hours_fee.employee.join_scal_date.present? && c2_amount == 0
                diff_year = (Date.difference_in_months(end_month, hours_fee.employee.join_scal_date)/12.0).round(2)
                c2_amount = service_c_2_perf.get_amount_by_column('D', diff_year)
              end
              hours_fee.fly_fee = hours_fee.fly_fee - c2_amount < global["minimum_wage"] ? global["minimum_wage"].round(2) : (hours_fee.fly_fee - c2_amount).round(2)
              calc_step.push_step("#{calc_step.step_notes.size + 1}. 12个日历月内累计旷工 #{year_absenteeism_days} 天, " +
                "空勤（空勤、空保）人员的考核性收入参照相同工作年限的地面客运服务岗位" +
                "（服务C-2的合格）的考核标准(#{c2_amount})扣发。扣发后按照上年度成都市最低工资标准(#{global["minimum_wage"]})保底, " +
                "小时费扣除相应金额后为: #{hours_fee.fly_fee}")
              # is_deduct_absenteeism = true
            elsif year_absenteeism_days >= 2
              hours_fee.fly_fee = 0
              calc_step.push_step("#{calc_step.step_notes.size + 1}. 12个日历月内累计旷工 #{year_absenteeism_days} 天, " +
                "小时费金额为: 0")
              is_deduct_absenteeism = true
              hours_fee.employee.hours_fees.where(month:hours_fee_months).update_all(is_deduct_absenteeism: true)
            end


            if summary
              # 迟到/早退
              year_late_days = year_summaries.map(&:late_or_leave).map(&:to_f).inject(&:+).to_f
              if summary.late_or_leave.to_f > 0 && year_late_days >= 3
                hours_fee.fly_fee -= convert_standard
                calc_step.push_step("#{calc_step.step_notes.size + 1}. 根据薪酬设置, 工作时间为" +
                  "#{diff_year}年的服务 C-1 的合格绩效薪酬基数: #{convert_standard}, " +
                  "12个日历月内迟到、早退 #{year_late_days.to_i} 次，小时费扣除相应金额后为: #{hours_fee.fly_fee}")
              end
            end

            if is_land_work
              if %w(领导 干部).include?(hours_fee.employee.category.try(:display_name)) or setup.technical_grade.present?
                if department_fee > hours_fee.fly_fee
                  calc_step.push_step("#{calc_step.step_notes.size + 1}. (部门考核性收入分配结果: #{salary.try(:department_distribute).to_f} * " +
                    "公司绩效系数: #{global_council["perf_execute"].to_f} + 部门留存分配结果: #{salary.try(:department_reserved).to_f})=" +
                    "#{department_fee} 大于 (实飞小时费+考勤+旷工+处分+干部补贴*个人比例)=#{hours_fee.fly_fee}, 小时费=#{department_fee}")
                  hours_fee.fly_fee = department_fee
                else
                  calc_step.push_step("#{calc_step.step_notes.size + 1}. (部门考核性收入分配结果: #{salary.try(:department_distribute).to_f} * " +
                    "公司绩效系数: #{global_council["perf_execute"].to_f} + 部门留存分配结果: #{salary.try(:department_reserved).to_f})=" +
                    "#{department_fee} 不大于 (实飞小时费+考勤+旷工+处分+干部补贴*个人比例)=#{hours_fee.fly_fee}, 小时费=#{hours_fee.fly_fee}")
                end
              else
                if department_fee > hours_fee.fly_fee
                  calc_step.push_step("#{calc_step.step_notes.size + 1}. (部门考核性收入分配结果: #{salary.try(:department_distribute).to_f} * " +
                    "公司绩效系数: #{global_council["perf_execute"].to_f} + 部门留存分配结果: #{salary.try(:department_reserved).to_f})=" +
                    "#{department_fee} 大于 (实飞小时费+考勤+旷工+处分+补贴*个人比例)=#{hours_fee.fly_fee}, 小时费=#{department_fee}")
                  hours_fee.fly_fee = department_fee
                else
                  calc_step.push_step("#{calc_step.step_notes.size + 1}. (部门考核性收入分配结果: #{salary.try(:department_distribute).to_f} * " +
                    "公司绩效系数: #{global_council["perf_execute"].to_f} + 部门留存分配结果: #{salary.try(:department_reserved).to_f})=" +
                    "#{department_fee} 不大于 (实飞小时费+考勤+旷工+处分+补贴*个人比例)=#{hours_fee.fly_fee}, 小时费=#{hours_fee.fly_fee}")
                end
              end
            end

            total_up_or_down_money = 0
            if %w(up down).include?(hours_fee.up_or_down)
              up_or_down_money = compute_up_or_down_money(hours_fee, true, setup.try(:airline_hour_fee), fly_attendant_hour, calc_step)

              total_up_or_down_money = (up_or_down_money.to_f*hours_fee.fly_hours.to_f).round(2)
              hours_fee.up_or_down_money = up_or_down_money

              calc_step.push_step("#{calc_step.step_notes.size + 1}. 该员工上浮下靠总时间为: " +
                "#{hours_fee.fly_hours.to_f}, 上浮下靠总金额为: #{total_up_or_down_money}")
            end

            hours_fee.fly_fee += total_up_or_down_money
          end

          step_size = calc_step.step_notes.size
          hours_fee.fertility_allowance = 0
          if !hours_fee.employee.is_trainee?
            if summary
              vacation_desc = hours_fee.employee.get_vacation_desc(month).try(:values).try(:join, ", ").to_s
              hours_fee.notes += ", " if hours_fee.notes.size > 0 && vacation_desc.size > 0
              hours_fee.notes += vacation_desc
              leave_days = summary.try(:lactation_leave).to_f + summary.try(:maternity_leave).to_f - summary.try(:miscarriage_leave).to_f
              if leave_days > 0
                days = (month + '-01').to_date.end_of_month.day
                hours_fee.fertility_allowance = (convert_standard/(days.to_f)).round(2)*leave_days

                calc_step.push_step("#{calc_step.step_notes.size + 1}. 根据薪酬设置, 工作时间为" +
                  "#{diff_year}年的服务 C-1 的合格绩效薪酬基数: #{convert_standard}," +
                  " 产假(排除流产产假)+哺乳假:#{leave_days}天, 当月自然日:#{days}天, 生育津贴为: #{hours_fee.fertility_allowance}")
              end
            end
            calc_step.push_step("#{calc_step.step_notes.size + 1}. 产假(排除流产产假)+哺乳假:0天, 生育津贴为: 0") if calc_step.step_notes.size == step_size
          end
          calc_step.push_step("#{calc_step.step_notes.size + 1}. 实习人员, 生育津贴为: 0") if calc_step.step_notes.size == step_size
        end

        ## 地面兼职补贴
        if hours_fee.is_land_work && hours_security.blank?
          hours_fee.fly_fee += hours_fee.land_work_money.to_f
          calc_step.push_step("#{calc_step.step_notes.size + 1}. 参与地面兼职补贴，补贴金额为:#{hours_fee.land_work_money.to_f}")
        end

        if hours_fee.fly_fee < 0
          hours_fee.fly_fee = 0
          calc_step.push_step("#{calc_step.step_notes.size + 1}. 如小时费小于 0, 则小时费最后为 0")
        end


        hours_fee.airline_fee = 0
        if hours_security.blank? && setup.is_send_airline_fee
          if %w(领导 干部).include?(hours_fee.employee.category.try(:display_name))
            if hours_fee.fly_hours && hours_fee.fly_hours > 0
              airline_fee = 912.5
              if hours_fee.fly_fee + hours_fee.add_garnishee.to_f >= airline_fee
                hours_fee.airline_fee = airline_fee
                calc_step.push_step("#{calc_step.step_notes.size + 1}. 干部只要有飞行时间, 空勤灶为 912.5")

                fly_fee = (hours_fee.fly_fee - hours_fee.airline_fee).round(2)
                calc_step.push_step("#{calc_step.step_notes.size + 1}. 干部有飞行时间, 当月小时费：(#{hours_fee.fly_fee}" +
                  "-#{hours_fee.airline_fee})= #{fly_fee}")
                hours_fee.fly_fee = fly_fee
              else
                calc_step.push_step("#{calc_step.step_notes.size + 1}. 干部有飞行时间, 空勤灶(912.5) > " +
                  "小时费(#{hours_fee.fly_fee}) + 补扣发(#{hours_fee.add_garnishee.to_f}), 小时费不扣除空勤灶, 无空勤灶")
              end
            else
              calc_step.push_step("#{calc_step.step_notes.size + 1}. 干部当月无飞行时间, 无空勤灶, 小时费不扣除空勤灶")
            end
          else
            airline_fee = hours_fee.fly_hours.to_f*10 > 912.5 ? 912.5 : hours_fee.fly_hours.to_f*10
            if hours_fee.fly_fee + hours_fee.add_garnishee.to_f >= airline_fee
              hours_fee.airline_fee = hours_fee.fly_hours.to_f*10 + summary.try(:recuperate_leave).to_f * 30 > 912.5 ? 912.5 : hours_fee.fly_hours.to_f*10 + summary.try(:recuperate_leave).to_f * 30
              calc_step.push_step("#{calc_step.step_notes.size + 1}. 空勤灶: 飞行时间(保留两位)*10 + 疗养假 *30, 最多发放 912.5, #{month}为:#{hours_fee.airline_fee}")

              fly_fee = (hours_fee.fly_fee - airline_fee).round(2)
              calc_step.push_step("#{calc_step.step_notes.size + 1}. 飞行时间(保留两位)*10, 最多 912.5, 当月小时费：(#{hours_fee.fly_fee}" +
                "-#{airline_fee})= #{fly_fee}")
              hours_fee.fly_fee = fly_fee
            else
              calc_step.push_step("#{calc_step.step_notes.size + 1}. 飞行时间(保留两位)*10, 最多 912.5(#{airline_fee}) > " +
                "小时费(#{hours_fee.fly_fee}) + 补扣发(#{hours_fee.add_garnishee.to_f}), 小时费不扣除空勤灶, 无空勤灶")
            end
          end
        end

        total = hours_fee.fly_fee + hours_fee.fertility_allowance.to_f

        values << [hours_fee.employee_no, hours_fee.employee_name, hours_fee.department_name, hours_fee.position_name,
          hours_fee.month, hours_fee.channel_id, hours_fee.employee_id, hours_fee.fly_hours, hours_fee.fly_fee,
          hours_fee.airline_fee, hours_fee.reality_fly_hours, hours_fee.total_hours_fee, hours_fee.total_security_fee,
          hours_fee.hours_fee_difference, hours_fee.refund_fee, hours_fee.up_or_down, hours_fee.up_or_down_money,
          hours_fee.performance_revenue, hours_fee.fertility_allowance, hours_fee.ground_subsidy,
          hours_fee.hours_fee_category, total, hours_fee.add_garnishee.to_f, hours_fee.notes, hours_fee.employee.salary_set_book,
          hours_fee.remark, hours_fee.is_not_fly_sky, hours_fee.is_land_work, hours_fee.land_work_money, 0,
          hours_fee.delicacy_reward, hours_fee.demo_fly_money, is_deduct_absenteeism]
        calc_values << [calc_step.employee_id, calc_step.month, calc_step.category, calc_step.step_notes, total]
        if other_employee_ids.include?(hours_fee.employee_id)
          airline_values << [hours_fee.employee_id, hours_fee.employee_no, hours_fee.employee_name,
            hours_fee.department_name, hours_fee.position_name, hours_fee.month, hours_fee.airline_fee,
            nil, nil, nil, hours_fee.notes, hours_fee.airline_fee, '乘务员']
        end
      end
      CalcStep.where("month='#{month}' and category='hours_fee/service' and employee_id in (?)", employee_ids).delete_all
      HoursFee.where("month='#{month}' and hours_fee_category='乘务员' and employee_id in (?)", employee_ids).delete_all
      AirlineFee.where("month='#{month}' and (hours_fee_category='乘务员' or employee_id in (?))", other_employee_ids).delete_all

      CalcStep.import(CalcStep::COLUMNS, calc_values, validate: false)
      HoursFee.import(HoursFee::COLUMNS, values, validate: false)
      AirlineFee.import(HoursFee::AIRLINE_COLUMNS, airline_values, validate: false)
    end

    def compute_security(month, hours_fee_category)
      hours_fees = HoursFee.joins(:employee).includes(employee: [:channel, :category, :salary_person_setup, :hours_fees, :punishments,
        :attendance_summaries, :performance_salaries, :special_states, :department]).where("hours_fees.hours_fee_category = '#{hours_fee_category}'
        and hours_fees.month = '#{month}'")
      fly_attendant_hour = Salary.find_by(category: 'fly_attendant_hour').form_data
      air_security_hour = Salary.find_by(category: 'air_security_hour').form_data

      service_c_1_perf = Salary.find_by(category: 'service_c_1_perf')
      service_c_2_perf = Salary.find_by(category: 'service_c_2_perf')
      global = Salary.find_by(category: 'global').form_data
      global_council = global["coefficient"][month]
      global_council ||= {}
      values, calc_values, airline_values, employee_ids = [], [], [], []
      start_month = (month + '-01').to_date.beginning_of_month
      end_month = (month + '-01').to_date.end_of_month
      is_deduct_absenteeism = false
      hours_fees.each do |hours_fee|
        employee_ids << hours_fee.employee_id and next if employee_ids.include?(hours_fee.employee_id)
        employee_ids << hours_fee.employee_id
        setup = hours_fee.employee.salary_person_setup
        hours_airline = hours_fee.employee.hours_fees.select{|h| h.month == month && h.hours_fee_category == '乘务员'}.first
        next if hours_fee.employee.channel.try(:display_name) != '空勤' || ['', '无'].include?(setup.try(:security_hour_fee)) || (hours_airline && ['', '无'].include?(setup.try(:airline_hour_fee)))
        return [false, "#{hours_fee.employee.name}  #{hours_fee.employee.employee_no}缺少个人薪酬设置或小时费设置错误"] if setup.blank? || air_security_hour[setup.try(:security_hour_fee)].blank?
        calc_step = CalcStep.new employee_id: hours_fee.employee_id, month: month, category: 'hours_fee/security'
        hours_fee.notes = ''
        return [false, "#{hours_fee.employee.name}  #{hours_fee.employee.employee_no}缺少个人薪酬设置或小时费设置错误"] if hours_airline && fly_attendant_hour[setup.try(:airline_hour_fee)].blank?
        hours_fee.up_or_down_money = nil
        hours_fee.fly_fee = hours_fee.total_hours_fee.to_f + hours_fee.delicacy_reward.to_f
        calc_step.push_step("#{calc_step.step_notes.size + 1}. 本月空保飞行时间为：#{hours_fee.fly_hours.to_f}，空保小时费 = " +
          "导入小时费(#{hours_fee.total_hours_fee.to_f}) + 空勤精编奖励(#{hours_fee.delicacy_reward.to_f})")

        if hours_airline
          hours_fee.fly_fee += hours_airline.total_hours_fee.to_f + hours_airline.delicacy_reward.to_f
          calc_step.push_step("#{calc_step.step_notes.size + 1}. 本月空乘飞行时间为：#{hours_airline.fly_hours.to_f}，空乘小时费为：" +
            "#{hours_airline.total_hours_fee.to_f}, 空勤精编奖励(#{hours_airline.delicacy_reward.to_f})")
        end

        summary = hours_fee.employee.attendance_summaries.select{|s| s.summary_date == month}.first

        is_land_work = hours_fee.employee.special_states.select{|s| (s.special_category == '空勤地面' || 
          s.special_category == '借调') &&
          ((s.special_date_from < start_month && (s.special_date_to.blank? || s.special_date_to >
          end_month)) || (s.special_date_from >= start_month && s.special_date_from <= end_month) ||
          (s.special_date_to && s.special_date_to >= start_month && s.special_date_to <= end_month))
          }.present?
        is_full_land_work = hours_fee.employee.special_states.select{|s| (s.special_category == '空勤地面' || 
          s.special_category == '借调') &&
          (s.special_date_from <= start_month && (s.special_date_to.blank? || s.special_date_to >=
          end_month))}.present?

        punishment_type = excute_punishment(hours_fee, month, air_security_hour, setup, calc_step, 2)
        airline_punishment_type = excute_punishment(hours_airline, month, fly_attendant_hour, setup, 1) if punishment_type && hours_airline
        if punishment_type == 'all'
          hours_fee.fly_fee = 0
          hours_airline.fly_fee = 0 if hours_airline
        else
          type = airline_or_security?(hours_fee, fly_attendant_hour, air_security_hour)

          if hours_airline
            hours_airline.up_or_down_money = nil
            hours_airline.fly_fee = hours_airline.total_hours_fee.to_f
          end
          salary = hours_fee.employee.performance_salaries.select{|p| p.month == month}.first
          department_fee = (salary.try(:department_distribute).to_f*global_council["perf_execute"].to_f + salary.try(:department_reserved).to_f).round(2)
          department_fee = salary.try(:base_salary).to_f if department_fee == 0

          diff_year = hours_fee.employee.scal_working_years.to_i
          convert_standard = service_c_1_perf.get_amount_by_column('C', diff_year)
          if hours_fee.employee.join_scal_date.present? && convert_standard == 0
            diff_year = (Date.difference_in_months(end_month, hours_fee.employee.join_scal_date)/12.0).round(2)
            convert_standard = service_c_1_perf.get_amount_by_column('D', diff_year)
          end

          if is_full_land_work
            hours_fee.fly_fee = department_fee
            calc_step.push_step("#{calc_step.step_notes.size + 1}. 整月空勤停飞上地面行政班, 当月小时费=部门考核性收入分配结果(#{salary.try(:department_distribute).to_f}" +
              ")*公司绩效系数(#{global_council["perf_execute"].to_f})+部门留存分配结果(#{salary.try(:department_reserved).to_f})")
          else
            if punishment_type.to_f > 0
              punishment_money = (punishment_type.to_f*hours_fee.fly_hours.to_f).round(2)
              calc_step.push_step("#{calc_step.step_notes.size + 1}. 安全员飞行处分扣款: 差额(#{punishment_type.to_f})*飞行时间(#{hours_fee.fly_hours.to_f})=#{punishment_money}")
              hours_fee.fly_fee -= punishment_money
              if hours_airline
                punishment_money = (airline_punishment_type.to_f*hours_airline.try(:fly_hours).to_f).round(2)
                calc_step.push_step("#{calc_step.step_notes.size + 1}. 乘务员飞行处分扣款: 差额(#{airline_punishment_type.to_f})*飞行时间(#{hours_airline.try(:fly_hours).to_f})=#{punishment_money}")
                hours_airline.fly_fee -= punishment_money
              end
            end

            if %w(领导 干部).include?(hours_fee.employee.category.try(:display_name)) || setup.technical_grade.present?
              month_days = Date.parse(month + "-01").end_of_month.day
              proportion1 = summary.try(:paid_leave).to_f > 0 ? (month_days - summary.try(:paid_leave).to_f)/month_days.to_f : 1
              proportion = hours_fee.fly_hours.to_f > setup.lower_limit_hour.to_f || (hours_fee.fly_hours.to_f > 0 &&
                setup.is_flyer_land_work) || setup.lower_limit_hour.to_f == 0 ? 1 : hours_fee.fly_hours.to_f/(setup.lower_limit_hour.to_f*proportion1)
              proportion = 1 if proportion > 1
              proportion = 0 if proportion1 == 0

              if is_land_work || %w(空保大队 客舱服务部).include?(hours_fee.employee.department.full_name.split('-').first)
                hour_money = type == 'true' ? fly_attendant_hour[setup.try(:airline_hour_fee)] : air_security_hour[setup.try(:security_hour_fee)]
                hours_fee.hours_fee_difference = setup.leader_subsidy_hour.to_f*proportion*hour_money
                step_note = "享受干部补贴, 干部岗位薪酬等级:#{setup.leader_grade}, " +
                  "最低飞行时间:#{setup.lower_limit_hour}, 本月带薪假合计:#{summary.try(:paid_leave).to_f}, 干部补贴飞行时间:#{setup.leader_subsidy_hour.to_f}*小时费标准:" +
                  "#{hour_money}*比例:"
                if proportion == 1
                  step_note += "1 = #{hours_fee.hours_fee_difference}"
                else
                  step_note += "#{hours_fee.fly_hours.to_f}/(#{setup.lower_limit_hour.to_f}*#{month_days - summary.try(:paid_leave).to_f}/#{month_days}) = #{hours_fee.hours_fee_difference}"
                end
                calc_step.push_step("#{calc_step.step_notes.size + 1}. " + step_note)
              else
                hours_fee.hours_fee_difference = department_fee * proportion
                step_note = "享受干部补贴, (部门考核性收入分配结果: #{salary.try(:department_distribute).to_f} * 公司绩效系数: " +
                  "#{global_council["perf_execute"].to_f} + 部门留存分配结果: #{salary.try(:department_reserved).to_f}) * 比例: "
                if proportion == 1
                  step_note += "1 = #{hours_fee.hours_fee_difference}"
                else
                  step_note += "#{hours_fee.fly_hours.to_f}/(#{setup.lower_limit_hour.to_f}*#{month_days - summary.try(:paid_leave).to_f}/#{month_days}) = #{hours_fee.hours_fee_difference}"
                end
                calc_step.push_step("#{calc_step.step_notes.size + 1}. " + step_note)
              end

              hours_fee.hours_fee_difference = 0 if hours_fee.hours_fee_difference.to_f <= 0
              hours_fee.fly_fee += hours_fee.hours_fee_difference
            end

            # 旷工
            year_summaries = hours_fee.employee.attendance_summaries.select{|s| (s.summary_date + '-01').to_date <= (month + '-01').to_date && (s.summary_date + '-01').to_date > (month + '-01').to_date.last_year}
            month_absenteeism_days = hours_fee.employee.attendance_summaries.where(summary_date:month).first.absenteeism.to_f
            year_absenteeism_days = 0
            hours_fee_months = []
            
            if month_absenteeism_days > 0
              year_summaries_month = year_summaries.map(&:summary_date)
              hours_fee_months = hours_fee.employee.hours_fees.select{|h| year_summaries_month.include?(h.month) && !h.is_deduct_absenteeism}.map(&:month)
              year_absenteeism_days = hours_fee.employee.attendance_summaries.select{|a| hours_fee_months.include?(a.summary_date)}.map(&:absenteeism).map(&:to_f).inject(:+).to_f
            elsif month_absenteeism_days == 0
              year_absenteeism_days = 0
              # hours_fee_months = Range.new((month + '-01').to_date.last_year.next_month, (month + '-01').to_date).to_a.map{|m| m.strftime("%Y-%m")}.uniq
              # month_hours_fee = hours_fee.employee.hours_fees.select{|h| hours_fee_months.include?(h.month) && h.is_deduct_absenteeism}
              # year_absenteeism_days = year_summaries.map(&:absenteeism).map(&:to_f).inject(&:+).to_f if month_hours_fee.blank?
            end
            if year_absenteeism_days > 0 && year_absenteeism_days < 2
              diff_year = hours_fee.employee.scal_working_years.to_i
              c2_amount = service_c_2_perf.get_amount_by_column('C', hours_fee.employee.scal_working_years.to_i)
              if hours_fee.employee.join_scal_date.present? && c2_amount == 0
                diff_year = (Date.difference_in_months(end_month, hours_fee.employee.join_scal_date)/12.0).round(2)
                c2_amount = service_c_2_perf.get_amount_by_column('D', diff_year)
              end
              hours_fee.fly_fee = hours_fee.fly_fee - c2_amount < global["minimum_wage"] ? global["minimum_wage"].round(2) : (hours_fee.fly_fee - c2_amount).round(2)
              calc_step.push_step("#{calc_step.step_notes.size + 1}. 12个日历月内累计旷工 #{year_absenteeism_days} 天, " +
                "空勤（空勤、空保）人员的考核性收入参照相同工作年限的地面客运服务岗位" +
                "（服务C-2的合格）的考核标准(#{c2_amount})扣发。扣发后按照上年度成都市最低工资标准(#{global["minimum_wage"]})保底, " +
                "小时费扣除相应金额后为: #{hours_fee.fly_fee}")
              # is_deduct_absenteeism = true
            elsif year_absenteeism_days >= 2
              hours_fee.fly_fee = 0
              calc_step.push_step("#{calc_step.step_notes.size + 1}. 12个日历月内累计旷工 #{year_absenteeism_days} 天, " +
                "小时费金额为: 0")
              is_deduct_absenteeism = true
              hours_fee.employee.hours_fees.where(month: hours_fee_months).update_all(is_deduct_absenteeism: true)
            end
            
            

            if summary
              # 迟到/早退
              year_late_days = year_summaries.map(&:late_or_leave).map(&:to_f).inject(&:+).to_f
              if summary.late_or_leave.to_f > 0 && year_late_days >= 3
                hours_fee.fly_fee -= convert_standard
                calc_step.push_step("#{calc_step.step_notes.size + 1}. 根据薪酬设置, 工作时间为" +
                  "#{diff_year}年的服务 C-1 的合格绩效薪酬基数: #{convert_standard}, " +
                  "12个日历月内迟到、早退 #{year_late_days.to_i} 次，扣除相应金额后小时费为: #{hours_fee.fly_fee}")
              end
            end

            if is_land_work
              if %w(领导 干部).include?(hours_fee.employee.category.try(:display_name)) or setup.technical_grade.present?
                if department_fee > hours_fee.fly_fee
                  calc_step.push_step("#{calc_step.step_notes.size + 1}. (部门考核性收入分配结果: #{salary.try(:department_distribute).to_f} * " +
                    "公司绩效系数: #{global_council["perf_execute"].to_f} + 部门留存分配结果: #{salary.try(:department_reserved).to_f})=" +
                    "#{department_fee} 大于 (实飞小时费+考勤+旷工+处分+干部补贴*个人比例)=#{hours_fee.fly_fee}" +
                    ", 小时费=#{department_fee}")
                  hours_fee.fly_fee = department_fee
                else
                  calc_step.push_step("#{calc_step.step_notes.size + 1}. (部门考核性收入分配结果: #{salary.try(:department_distribute).to_f} * " +
                    "公司绩效系数: #{global_council["perf_execute"].to_f} + 部门留存分配结果: #{salary.try(:department_reserved).to_f})=" +
                    "#{department_fee} 不大于 (实飞小时费+考勤+旷工+处分+干部补贴*个人比例)=#{hours_fee.fly_fee}" +
                    ", 小时费=#{hours_fee.fly_fee}")
                end
              else
                if department_fee > hours_fee.fly_fee
                  calc_step.push_step("#{calc_step.step_notes.size + 1}. (部门考核性收入分配结果: #{salary.try(:department_distribute).to_f} * " +
                    "公司绩效系数: #{global_council["perf_execute"].to_f} + 部门留存分配结果: #{salary.try(:department_reserved).to_f})=" +
                    "#{department_fee} 大于 (实飞小时费+考勤+旷工+处分+补贴*个人比例)=#{hours_fee.fly_fee}" +
                    ", 小时费=#{department_fee}")
                  hours_fee.fly_fee = department_fee
                else
                  calc_step.push_step("#{calc_step.step_notes.size + 1}. (部门考核性收入分配结果: #{salary.try(:department_distribute).to_f} * " +
                    "公司绩效系数: #{global_council["perf_execute"].to_f} + 部门留存分配结果: #{salary.try(:department_reserved).to_f})=" +
                    "#{department_fee} 不大于 (实飞小时费+考勤+旷工+处分+补贴*个人比例)=#{hours_fee.fly_fee}" +
                    ", 小时费=#{hours_fee.fly_fee}")
                end
              end
            end

            total_up_or_down_money = 0
            if %w(up down).include?(hours_fee.up_or_down) || %w(up down).include?(hours_airline.try(:up_or_down))
              value = %w(up down).include?(hours_fee.up_or_down) ? hours_fee : hours_airline
              up_or_down_money = 0
              if type == 'true'
                up_or_down_money = compute_up_or_down_money(value, true, setup.try(:airline_hour_fee), fly_attendant_hour, calc_step)
              end
              if type == 'false'
                up_or_down_money = compute_up_or_down_money(value, false, setup.try(:security_hour_fee), air_security_hour, calc_step)
              end

              total_up_or_down_money = (up_or_down_money.to_f*(hours_fee.fly_hours.to_f + hours_airline.try(:fly_hours).to_f)).round(2)
              hours_fee.up_or_down_money = up_or_down_money

              calc_step.push_step("#{calc_step.step_notes.size + 1}. 该员工上浮下靠总时间为: " +
                "#{hours_fee.fly_hours.to_f + hours_airline.try(:fly_hours).to_f}, 上浮下靠总金额为: #{total_up_or_down_money}")
            end

            hours_fee.fly_fee += total_up_or_down_money
          end

          step_size = calc_step.step_notes.size
          hours_fee.fertility_allowance = 0
          if !hours_fee.employee.is_trainee?
            if summary
              vacation_desc = hours_fee.employee.get_vacation_desc(month).try(:values).try(:join, ", ").to_s
              hours_fee.notes += ", " if hours_fee.notes.size > 0 && vacation_desc.size > 0
              hours_fee.notes += vacation_desc
              leave_days = summary.try(:lactation_leave).to_f + summary.try(:maternity_leave).to_f - summary.try(:miscarriage_leave).to_f
              if leave_days > 0
                days = (month + '-01').to_date.end_of_month.day
                hours_fee.fertility_allowance = (convert_standard/(days.to_f)).round(2)*leave_days

                calc_step.push_step("#{calc_step.step_notes.size + 1}. 根据薪酬设置, 工作时间为" +
                  "#{diff_year}年的服务 C-1 的合格绩效薪酬基数: #{convert_standard}," +
                  " 产假(排除流产产假)+哺乳假:#{leave_days}天, 当月自然日:#{days}天, 生育津贴为: #{hours_fee.fertility_allowance}")
              end
            end
            calc_step.push_step("#{calc_step.step_notes.size + 1}. 产假(排除流产产假)+哺乳假:0天, 生育津贴为: 0") if calc_step.step_notes.size == step_size
          end
          calc_step.push_step("#{calc_step.step_notes.size + 1}. 实习人员, 生育津贴为: 0") if calc_step.step_notes.size == step_size
        end

        ## 地面兼职补贴
        if hours_fee.is_land_work || hours_airline.try(:is_land_work)
          land_work_money = hours_fee.land_work_money.to_f > hours_airline.try(:land_work_money).to_f ? hours_fee.land_work_money.to_f : hours_airline.try(:land_work_money).to_f
          hours_fee.fly_fee += land_work_money
          calc_step.push_step("#{calc_step.step_notes.size + 1}. 参与地面兼职补贴，补贴金额为:#{land_work_money}")
        end

        if hours_fee.fly_fee < 0
          hours_fee.fly_fee = 0
          calc_step.push_step("#{calc_step.step_notes.size + 1}. 如小时费小于 0, 则小时费最后为 0")
        end

        hours_fee.airline_fee = 0
        if setup.is_send_airline_fee
          if %w(领导 干部).include?(hours_fee.employee.category.try(:display_name))
            if (hours_fee.fly_hours && hours_fee.fly_hours > 0) || (hours_airline.try(:fly_hours) && hours_airline.fly_hours > 0)
              if hours_fee.fly_fee + hours_fee.add_garnishee.to_f >= hours_fee.airline_fee
                hours_fee.airline_fee = 912.5
                calc_step.push_step("#{calc_step.step_notes.size + 1}. 干部只要有飞行时间, 空勤灶为 912.5")

                fly_fee = (hours_fee.fly_fee - hours_fee.airline_fee).round(2)
                calc_step.push_step("#{calc_step.step_notes.size + 1}. 干部有飞行时间, 当月小时费：(#{hours_fee.fly_fee}" +
                  "-#{hours_fee.airline_fee})= #{fly_fee}")
                hours_fee.fly_fee = fly_fee
              else
                calc_step.push_step("#{calc_step.step_notes.size + 1}. 干部有飞行时间, 空勤灶(912.5) > " +
                  "小时费(#{hours_fee.fly_fee}) + 补扣发(#{hours_fee.add_garnishee.to_f}), 小时费不扣除空勤灶, 无空勤灶")
              end
            else
              calc_step.push_step("#{calc_step.step_notes.size + 1}. 干部当月无飞行时间, 无空勤灶, 小时费不扣除空勤灶")
            end
          else
            airline_fee = (hours_fee.fly_hours.to_f + hours_airline.try(:fly_hours).to_f)*10 > 912.5 ? 912.5 :
                  (hours_fee.fly_hours.to_f + hours_airline.try(:fly_hours).to_f)*10
            if hours_fee.fly_fee + hours_fee.add_garnishee.to_f >= airline_fee
              hours_fee.airline_fee = (hours_fee.fly_hours.to_f + hours_airline.try(:fly_hours).to_f)*10 +
                summary.try(:recuperate_leave).to_f * 30 > 912.5 ? 912.5 : (hours_fee.fly_hours.to_f +
                hours_airline.try(:fly_hours).to_f)*10 + summary.try(:recuperate_leave).to_f * 30
              calc_step.push_step("#{calc_step.step_notes.size + 1}. 空勤灶: 飞行时间(保留两位)*10 + 疗养假 *30, 最多发放 912.5, #{month}为:#{hours_fee.airline_fee}")

              fly_fee = (hours_fee.fly_fee - airline_fee).round(2)
              calc_step.push_step("#{calc_step.step_notes.size + 1}. 飞行时间(保留两位)*10, 最多 912.5, 当月小时费：(#{hours_fee.fly_fee}" +
                "-#{airline_fee})= #{fly_fee}")
              hours_fee.fly_fee = fly_fee
            else
              calc_step.push_step("#{calc_step.step_notes.size + 1}. 飞行时间(保留两位)*10, 最多 912.5(#{airline_fee}) > " +
                "小时费(#{hours_fee.fly_fee}) + 补扣发(#{hours_fee.add_garnishee.to_f}), 小时费不扣除空勤灶, 无空勤灶")
            end
          end
        end

        total = hours_fee.fly_fee + hours_fee.fertility_allowance.to_f

        values << [hours_fee.employee_no, hours_fee.employee_name, hours_fee.department_name, hours_fee.position_name,
          hours_fee.month, hours_fee.channel_id, hours_fee.employee_id, hours_fee.fly_hours, hours_fee.fly_fee,
          hours_fee.airline_fee, hours_fee.reality_fly_hours, hours_fee.total_hours_fee, hours_fee.total_security_fee,
          hours_fee.hours_fee_difference, hours_fee.refund_fee, hours_fee.up_or_down || hours_airline.try(:up_or_down),
          hours_fee.up_or_down_money, hours_fee.performance_revenue, hours_fee.fertility_allowance,
          hours_fee.ground_subsidy, hours_fee.hours_fee_category, total, hours_fee.add_garnishee.to_f, hours_fee.notes,
          hours_fee.employee.salary_set_book, hours_fee.remark, hours_fee.is_not_fly_sky, hours_fee.is_land_work,
          hours_fee.land_work_money, 0, hours_fee.delicacy_reward, hours_fee.demo_fly_money, is_deduct_absenteeism]
        calc_values << [calc_step.employee_id, calc_step.month, calc_step.category, calc_step.step_notes, total]

        if hours_airline
          values << [hours_fee.employee_no, hours_fee.employee_name, hours_fee.department_name, hours_fee.position_name,
            hours_fee.month, hours_fee.channel_id, hours_fee.employee_id, hours_airline.fly_hours, 0,
            0, hours_airline.reality_fly_hours, hours_airline.total_hours_fee, hours_airline.total_security_fee, 0,
            hours_airline.refund_fee, 0, 0, hours_fee.performance_revenue, 0, hours_fee.ground_subsidy,
            hours_airline.hours_fee_category, 0, hours_airline.add_garnishee.to_f, hours_fee.notes,
            hours_fee.employee.salary_set_book, hours_airline.remark, hours_airline.is_not_fly_sky,
            hours_airline.is_land_work, hours_airline.land_work_money, 0, hours_airline.delicacy_reward,
            hours_airline.demo_fly_money, is_deduct_absenteeism]
          calc_values << [calc_step.employee_id, calc_step.month, 'hours_fee/service', calc_step.step_notes, 0]
        end
        airline_values << [hours_fee.employee_id, hours_fee.employee_no, hours_fee.employee_name,
          hours_fee.department_name, hours_fee.position_name, hours_fee.month, hours_fee.airline_fee,
          nil, nil, nil, hours_fee.notes, hours_fee.airline_fee, '安全员']
      end

      CalcStep.where("month='#{month}' and (category='hours_fee/security' or category='hours_fee/service')
        and employee_id in (?)", employee_ids).delete_all
      HoursFee.where("month='#{month}' and (hours_fee_category='乘务员' or hours_fee_category='安全员')
        and employee_id in (?)", employee_ids).delete_all
      AirlineFee.where("month='#{month}' and (hours_fee_category='安全员' or employee_id in (?))", employee_ids).delete_all

      CalcStep.import(CalcStep::COLUMNS, calc_values, validate: false)
      HoursFee.import(HoursFee::COLUMNS, values, validate: false)
      AirlineFee.import(HoursFee::AIRLINE_COLUMNS, airline_values, validate: false)
    end

    def airline_or_security?(hours_fee, fly_attendant_hour, air_security_hour)
      airline = hours_fee.employee.salary_person_setup.try(:airline_hour_fee)
      security = hours_fee.employee.salary_person_setup.try(:security_hour_fee)
      if airline.present? && security.present?
        if fly_attendant_hour[airline] >= air_security_hour[security]
          return 'true'
        else
          return 'false'
        end
      elsif airline.present?
        return 'true'
      elsif security.present?
        return 'false'
      else
        nil
      end
    end

    def airline_or_security(hours_fee, fly_attendant_hour, air_security_hour)
      airline = hours_fee.employee.salary_person_setup.airline_hour_fee
      security = hours_fee.employee.salary_person_setup.security_hour_fee

      if airline.present? && security.present?
        if fly_attendant_hour[airline] >= air_security_hour[security]
          return fly_attendant_hour[airline]
        else
          return air_security_hour[security]
        end
      elsif airline.present?
        return fly_attendant_hour[airline]
      elsif security.present?
        return air_security_hour[security]
      else
        nil
      end
    end

    def compute_up_or_down_money(hours_fee, is_airline, airline, fly_attendant_hour, calc_step)
      attendant_hour_fees = fly_attendant_hour.values.sort{ |x,y| y <=> x }
      attendant_hour_index = attendant_hour_fees.index(fly_attendant_hour[airline])
      up_or_down_money = 0
      if hours_fee.up_or_down == 'up'
        if fly_attendant_hour[airline] == attendant_hour_fees.max or %w(first_class_A safety_A).include?(airline)
          up_or_down_money = 5
        else
          up_or_down_money = attendant_hour_fees[attendant_hour_index - 1] - fly_attendant_hour[airline]
        end
      else
        if fly_attendant_hour[airline] == attendant_hour_fees.min || !is_airline
          up_or_down_money = 0
        else
          up_or_down_money = attendant_hour_fees[attendant_hour_index + 1] - fly_attendant_hour[airline]
        end
      end

      calc_step.push_step("#{calc_step.step_notes.size + 1}. 根据薪酬个人设置, 按#{is_airline ? '空乘' : '空保'}小时费" +
        "#{hours_fee.up_or_down == 'up' ? '上浮' : '下靠'}一等, 差额为: #{up_or_down_money.abs}元/小时")
      up_or_down_money
    end

    # 处分
    def excute_punishment(hours_fee, month, fly_attendant_hour, setup, calc_step = nil, is_airline)
      key = nil
      case is_airline
      when 0
        key = 'fly_hour_fee'
      when 1
        key = 'airline_hour_fee'
      when 2
        key = 'security_hour_fee'
      end

      start_month = (month + '-01').to_date.beginning_of_month
      end_month = (month + '-01').to_date.end_of_month
      publishments = hours_fee.employee.punishments.select{|p| p.genre == '处分' and (p.category == '警告' or
        p.category == '记过' or p.category == '留用察看') and (p.start_date.present? and p.end_date.present?) and
        ((p.start_date >= start_month and p.start_date <= end_month) or (p.end_date >= start_month and
        p.end_date <= end_month) or (p.start_date < start_month and p.end_date > end_month))}
      if publishments.present?
        liuyong = publishments.select{|p| p.category == '留用察看'}.first
        if liuyong.present?
          calc_step.push_step("#{calc_step.step_notes.size + 1}. 留用察看处分期间，当月小时费全月扣发") if calc_step
          hours_fee.notes = "#{liuyong.start_date}到#{liuyong.end_date}受到留用察看处分"
          return 'all'
        else
          jiguo = publishments.select{|p| p.category == '记过'}.first
          jinggao = publishments.select{|p| p.category == '警告'}.first
          if jiguo.present?
            hours_fee.notes = "#{jiguo.start_date}到#{jiguo.end_date}受到记过处分"
            if is_airline == 0 && ['observer', 'student'].include?(setup.try(key))
              standard = (fly_attendant_hour[setup.try(key)]*0.5).round(2)
              calc_step.push_step("#{calc_step.step_notes.size + 1}. 记过处分期间，最低档则按其档级标准的50%发放, 差额为：#{standard}/小时") if calc_step
              return standard
            end

            if is_airline == 0
              fly_attendant_hour.delete('observer')
              fly_attendant_hour.delete('student')
              fly_attendant_hour.delete('flyer_student_base')
            end
            attendant_hour_fees = fly_attendant_hour.values.sort{ |x,y| y <=> x }
            attendant_hour_index = attendant_hour_fees.index(fly_attendant_hour[setup.try(key)])

            if attendant_hour_fees[attendant_hour_index + 2].present?
              standard = (fly_attendant_hour[setup.try(key)] - attendant_hour_fees[attendant_hour_index + 2]).round(2)
              setup.send(key + '=', fly_attendant_hour.sort{ |x,y| y[1] <=> x[1] }[attendant_hour_index + 2][0])
              calc_step.push_step("#{calc_step.step_notes.size + 1}. 记过处分期间，当月小时费下调两个档级的标准发放, 差额为：#{standard}/小时") if calc_step
              return standard
            else
              standard = (attendant_hour_fees.min*0.5).round(2)
              calc_step.push_step("#{calc_step.step_notes.size + 1}. 记过处分期间，最低档则按其档级标准的50%发放, 差额为：#{standard}/小时") if calc_step
              return standard
            end
          else
            hours_fee.notes = "#{jinggao.start_date}到#{jinggao.end_date}受到警告处分"
            if is_airline == 0 && ['observer', 'student'].include?(setup.try(key))
              standard = (fly_attendant_hour[setup.try(key)]*0.2).round(2)
              calc_step.push_step("#{calc_step.step_notes.size + 1}. 警告处分期间，最低档则按其档级标准的80%发放, 差额为：#{standard}/小时") if calc_step
              return standard
            end

            if is_airline == 0
              fly_attendant_hour.delete('observer')
              fly_attendant_hour.delete('student')
              fly_attendant_hour.delete('flyer_student_base')
            end
            attendant_hour_fees = fly_attendant_hour.values.sort{ |x,y| y <=> x }
            attendant_hour_index = attendant_hour_fees.index(fly_attendant_hour[setup.try(key)])

            if fly_attendant_hour[setup.try(key)] != attendant_hour_fees.min
              standard = (fly_attendant_hour[setup.try(key)] - attendant_hour_fees[attendant_hour_index + 1]).round(2)
              setup.send(key + '=', fly_attendant_hour.sort{ |x,y| y[1] <=> x[1] }[attendant_hour_index + 1][0])
              calc_step.push_step("#{calc_step.step_notes.size + 1}. 警告处分期间，当月小时费下调一个档级的标准发放, 差额为：#{standard}/小时") if calc_step
              return standard
            else
              standard = (fly_attendant_hour[setup.try(key)]*0.2).round(2)
              calc_step.push_step("#{calc_step.step_notes.size + 1}. 警告处分期间，最低档则按其档级标准的80%发放, 差额为：#{standard}/小时") if calc_step
              return standard
            end
          end
        end
      end
      nil
    end

    def is_still_not_fly_sky?(hours_fees, month, number = 7)
      current_month = Date.parse(month + '-01')
      months = [month]

      (number - 1).downto(1) do |_|
        current_month = current_month.prev_month
        months.unshift(current_month.strftime("%Y-%m"))
      end

      months.map{|m|hours_fees.find_by(month: m).try(:is_not_fly_sky)}.select{|x|x}.size >= number
    end

    def get_refund_fee_remain(hours_fees, month)
      lower_month = hours_fees.map(&:month).sort.first
      return 0 if lower_month.blank? || lower_month == month
      prev_month = Date.parse(month + '-01').prev_month.strftime("%Y-%m")
      refund_fee_remain = hours_fees.select{|h| h.month == prev_month}.first.try(:refund_fee_remain)
      return refund_fee_remain if refund_fee_remain
      get_refund_fee_remain(hours_fees, prev_month)
    end
  end
end

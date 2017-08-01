class KeepSalary < ActiveRecord::Base
  belongs_to :employee

  validates :month, uniqueness: { scope: [:month, :employee_id] }

  COLUMNS = %w(employee_id month employee_no channel_id employee_name department_name position_name position performance working_years minimum_growth land_allowance life_1 life_2 adjustment_09 bus_14 communication_14 total add_garnishee notes remark)

  class << self
    def compute(month)
      prev_month = Date.parse(month + "-01").prev_month.strftime("%Y-%m")

      is_success, messages = AttendanceSummary.can_calc_salary?(prev_month)
      return [is_success, messages] unless is_success

      # 先全部删除计算记录
      @remark_hash = KeepSalary.where(month: month).index_by(&:employee_id)

      t1 = Time.new

      KeepSalary.transaction do
        @values = []
        @calc_values = []

        Employee.includes(:special_states, :salary_person_setup, :channel, :department, :master_positions, :labor_relation).find_in_batches(batch_size: 3000).with_index do |group, batch|
          puts "+-----------第 #{batch} 批 -----------+"
          group.each do |employee|
            next unless employee.salary_person_setup
            next if employee.salary_person_setup.try(:is_special_category)
            next if employee.is_service_a?

            # raise "#{employee.name} 缺少薪酬设置" if !employee.salary_person_setup

            hash = {employee_id: employee.id, category: 'keep_salary', month: month}
            calc_step = CalcStep.new(hash)

            @setup = employee.salary_person_setup

            # 基本工资计算的时候再来修改70%, 80%的问题，强制先算保留，再算基本工资
            #
            # if employee.is_continus_sick_leave_month(prev_month)
            #   @minimum_wage = Salary.find_by(category: 'global').form_data['minimum_wage']

            #   calc_step.push_step("连续 6 个月病假、病假工伤待定、怀孕待产全月不在岗")
            #   calc_step.push_step("当前成都市最低工资标准的 80% 为 #{@minimum_wage * 0.8}")

            #   @keep_total = @setup.keep_position.to_f + @setup.keep_performance.to_f + @setup.keep_working_years.to_f + @setup.keep_minimum_growth.to_f + @setup.keep_land_allowance.to_f + @setup.keep_life_allowance.to_f + @setup.keep_adjustment_09.to_f + @setup.keep_bus_14.to_f + @setup.keep_communication_14.to_f

            #   # 基本工资，保留工资，工龄工资
            #   calc_step.push_step("基本工资设置是 #{@setup.base_money.to_f}")
            #   calc_step.push_step("保留工资设置总和是 #{@keep_total}")
            #   calc_step.push_step("工龄工资的设置是 #{@setup.working_years_salary.to_f}")
            #   calc_step.push_step("基本工资、保留工资、工龄工资的总和的 70% 为 #{(@setup.base_money.to_f + @keep_total + @setup.working_years_salary.to_f) * 0.7}")

            #   @total = [(@setup.base_money.to_f + @keep_total + @setup.working_years_salary.to_f) * 0.7, @minimum_wage * 0.8].max
            #   calc_step.push_step("就高发，所得的保留工资总和应为 #{@total}")
            # end

            special_states = employee.special_states.select{|s| s.special_category == "空勤停飞"}

            if employee.is_trainee? || (employee.join_scal_date && employee.join_scal_date.strftime("%Y-%m") == month)
              calc_step.push_step("实习生或新进员工保留工资为 0")
              @total = 0
            elsif employee.is_fly_channel? && SpecialState.personal_stop_fly_months(special_states, prev_month) > 5
              calc_step.push_step("因个人原因空勤停飞的第 7 个月仅有基本工资，保留工资综合应为 0")
              @total = 0
            else
              # @total += @remark_hash[employee.id].try(:add_garnishee).to_f
              calc_step.push_step("保留工资设置如下:")
              calc_step.push_step("岗位工资保留 #{@setup.keep_position.to_f}")
              calc_step.push_step("业绩奖保留 #{@setup.keep_performance.to_f}")
              calc_step.push_step("工龄工资保留 #{@setup.keep_working_years.to_f}")
              calc_step.push_step("保底增幅 #{@setup.keep_minimum_growth.to_f}")
              calc_step.push_step("地勤补贴保留 #{@setup.keep_land_allowance.to_f}")
              calc_step.push_step("生活补贴保留1 #{@setup.keep_life_1.to_f}")
              calc_step.push_step("生活补贴保留2 #{@setup.keep_life_2.to_f}")
              calc_step.push_step("09调资增加保留 #{@setup.keep_adjustment_09.to_f}")
              calc_step.push_step("14公务用车保留 #{@setup.keep_bus_14.to_f}")
              calc_step.push_step("14通信补贴保留 #{@setup.keep_communication_14.to_f}")

              @total = @setup.keep_position.to_f + @setup.keep_performance.to_f + @setup.keep_working_years.to_f + @setup.keep_minimum_growth.to_f + @setup.keep_land_allowance.to_f + @setup.keep_life_1.to_f + @setup.keep_life_2.to_f + @setup.keep_adjustment_09.to_f + @setup.keep_bus_14.to_f + @setup.keep_communication_14.to_f
            end

            calc_step.final_amount(@total)

            @notes = employee.get_vacation_desc(prev_month).try(:values).try(:join, ", ").to_s
            @values << [employee.id, month, employee.employee_no, employee.channel_id, employee.name, employee.department.full_name, employee.master_position.name, @setup.keep_position.to_f, @setup.keep_performance.to_f, @setup.keep_working_years.to_f, @setup.keep_minimum_growth.to_f, @setup.keep_land_allowance.to_f, @setup.keep_life_1.to_f, @setup.keep_life_2.to_f, @setup.keep_adjustment_09.to_f, @setup.keep_bus_14.to_f, @setup.keep_communication_14.to_f, @total, @remark_hash[employee.id].try(:add_garnishee).to_f, @notes, @remark_hash[employee.id].try(:remark)]
            @calc_values << [calc_step.employee_id, calc_step.month, calc_step.category, calc_step.step_notes, calc_step.amount]
          end
        end

        KeepSalary.where(month: month).delete_all
        CalcStep.remove_items('keep_salary', month)

        CalcStep.import(CalcStep::COLUMNS, @calc_values, validate: false)
        KeepSalary.import(COLUMNS, @values, validate: false)

        @calc_values.clear
        @values.clear
      end


      t2 = Time.new
      puts "计算耗费 #{t2 - t1} 秒"

      return true
    end
  end
end

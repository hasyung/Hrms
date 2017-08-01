class BasicSalary < ActiveRecord::Base
  belongs_to :employee
  # default_scope {order("date(concat(basic_salaries.month, '-01')) desc")}

  COLUMNS = %w(employee_id month employee_name employee_no department_name
    position_name channel_id position_salary working_years_salary notes total add_garnishee
    salary_set_book standard deduct_money remark)

  validates :month, uniqueness: { scope: [:month, :employee_id] }

  def self.compute(month)
    BasicSalary.transaction do
      values, calc_values = [], []
      global = Salary.find_by(category: 'global').form_data
      compute_month = Date.parse(month + "-01").prev_month.strftime("%Y-%m")

      is_success, messages = AttendanceSummary.can_calc_salary?(compute_month)
      return [is_success, messages] unless is_success

      salaries_hash = BasicSalary.where(month: month).index_by(&:employee_id)
      zero_keep_salaries = []

      SalaryPersonSetup.joins(:employee).includes(employee: [:department, :channel, :attendance_summaries,
        :master_positions, :punishments, :keep_salaries, :special_states, :labor_relation, :basic_salaries]).each do |salary|
        channel = salary.employee.try(:channel).try(:display_name)
        is_paiqian = %w(骐骥劳务 骐骥劳务（协议） 蓝天劳务 蓝天劳务（协议）).include?(salary.employee.try(:labor_relation)
          .try(:display_name)) && channel != '空勤' && channel != '飞行'
        next if salary.is_salary_special || (is_paiqian && (salary.employee.join_scal_date.blank? || salary.employee.join_scal_date >= (month + '-01').to_date))

        calc_step = CalcStep.new employee_id: salary.employee_id, month: month, category: 'basic_salary'

        base_money = standard = base_standard = salary.base_money.to_f

        if salary.employee.join_scal_date.blank? || (salary.employee.join_scal_date.strftime("%Y-%m") == month &&
          salary.employee.join_scal_date.day >= 15) || (is_paiqian && salary.employee.join_scal_date.strftime("%Y-%m") ==
          compute_month && salary.employee.join_scal_date.day >= 15 && channel != '空勤')
          base_money = salary.base_money.to_f*0.5
          calc_step.push_step("#{calc_step.step_notes.size+1}. 基础薪酬: #{salary.base_wage ? I18n.t('salary.category.' + salary.base_wage) : '无'}, 档级: #{salary.base_flag}, 基础薪酬标准为: #{salary.base_money.to_f}, 当月15日（含）以后报到，按半月计发当月标准(#{standard})")
        else
          calc_step.push_step("#{calc_step.step_notes.size+1}. 基础薪酬: #{salary.base_wage ? I18n.t('salary.category.' + salary.base_wage) : '无'}, 档级: #{salary.base_flag}, 基础薪酬标准为: #{standard}")
        end

        working_years_salary = salary.working_years_salary.to_f
        if %w(服务A 服务B).include?(channel)
          working_years_salary = 0
          calc_step.push_step("#{calc_step.step_notes.size+1}. 员工通道为服务A或服务B， 工龄工资为: 0")
        else
          calc_step.push_step("#{calc_step.step_notes.size+1}. 员工工龄为: #{salary.employee.scal_working_years}年， 工龄工资为: #{salary.working_years_salary.to_f}")
        end
        notes = ''
        master_position = salary.employee.try(:master_positions).try(:first)
        special_states = salary.employee.special_states.select{|s| s.special_category == "空勤停飞"}

        if channel == '服务A'

        elsif channel == '飞行' && SpecialState.personal_stop_fly_months(special_states, compute_month) > 5
          base_money = standard = global["minimum_wage"].round(2)
          working_years_salary = 0
          notes = '个人不参加体检，或体检合格但个人原因无故停飞6个月含以上'
          calc_step.push_step("#{calc_step.step_notes.size + 1}. 个人不参加体检，或体检合格但个人原因无故停飞6个月含以上的，按照成都市最低工资标准计发基本工资(#{base_money})")
        else
          # 处分
          start_month = (compute_month + '-01').to_date.beginning_of_month
          end_month = (compute_month + '-01').to_date.end_of_month
          publishments = salary.employee.punishments.select{|p| p.genre == '处分' and (p.category == '警告' or
            p.category == '记过' or p.category == '留用察看') and (p.start_date.present? and p.end_date.present?) and
            ((p.start_date >= start_month and p.start_date <= end_month) or (p.end_date >= start_month and
            p.end_date <= end_month) or (p.start_date < start_month and p.end_date > end_month))}
          if publishments.present?
            liuyong = publishments.select{|p| p.category == '留用察看'}.first
            jiguo = publishments.select{|p| p.category == '记过'}.first
            jinggao = publishments.select{|p| p.category == '警告'}.first
            if liuyong.present?
              base_money = standard = global["minimum_wage"].round(2)
              working_years_salary = 0
              notes += "#{liuyong.start_date}到#{liuyong.end_date}受到留用察看处分"
              calc_step.push_step("#{calc_step.step_notes.size}. 留用察看处分期间，按成都市最低工资标准计发基本工资(#{base_money})")
            elsif channel == '服务B'
              if jiguo.present?
                base_money -= (standard*0.1).round(2)
                notes += "#{jiguo.start_date}到#{jiguo.end_date}受到记过处分"
                calc_step.push_step("#{calc_step.step_notes.size}. 记过处分期间，基本工资下调10%发放(#{(standard*0.1).round(2)})")
              elsif jinggao.present?
                base_money -= (standard*0.05).round(2)
                notes += "#{jinggao.start_date}到#{jinggao.end_date}受到警告处分"
                calc_step.push_step("#{calc_step.step_notes.size}. 警告处分期间，基本工资下调5%发放(#{(standard*0.05).round(2)})")
              end
            end
          end

          # 请假
          summary = salary.employee.attendance_summaries.select{|s| s.summary_date == compute_month}.first
          if summary.present? && channel != '飞行'
            vacation_desc = salary.employee.get_vacation_desc(compute_month).try(:values).try(:join, ", ").to_s
            notes += ', ' if notes.size > 0 && vacation_desc.size > 0
            notes += vacation_desc

            # 各项病假和空勤停飞
            sick_leave = summary.sick_leave.to_f + summary.sick_leave_injury.to_f + summary.sick_leave_nulliparous.to_f + 
              summary.ground.to_f

            if sick_leave > 0
              if salary.employee.is_continus_sick_leave_month(compute_month, special_states)
                a = (global["minimum_wage"]*0.8).round(2)
                keep_salary = salary.employee.keep_salaries.select{|k| k.month == month}.first
                b = ((keep_salary.try(:total).to_f + base_money + working_years_salary)*0.7).round(2)
                base_money = standard = a > b ? a : b

                zero_keep_salaries << keep_salary.id if keep_salary
                working_years_salary = 0
                calc_step.push_step("#{calc_step.step_notes.size + 1}. 员工因病或非因工受伤或空勤停飞6个月以上的，按以下两项就高选择其一执行：1. 成都市最低工资标准的80%(#{a}); 2. 本人月度工资收入（含基本工资项目、保留项目和股份工龄工资项目）的70%(#{b})")
              elsif salary.employee.start_working_years.to_i < 8 && salary.join_salary_scal_years.to_i < 8
                base_money = base_money - deduct_basic_by_days(standard, master_position, summary, true, compute_month, '病假', calc_step, special_states)
              else
                calc_step.push_step("#{calc_step.step_notes.size + 1}. 病假休假自然日(含空勤停飞)合计: #{sick_leave}天, 工作年限8年（含）以上的扣: 0元")
              end
            end

            # 事假
            if summary.personal_leave.to_f > 0
              base_money = base_money - deduct_basic_by_days(standard, master_position, summary, false, compute_month, '事假', calc_step)
            end

            # 迟到/早退
            year_summaries = salary.employee.attendance_summaries.select{|s| (s.summary_date + '-01').to_date <= (compute_month + '-01').to_date && (s.summary_date + '-01').to_date > (compute_month + '-01').to_date.last_year}
            year_late_days = year_summaries.map(&:late_or_leave).map(&:to_f).inject(&:+).to_f
            if summary.late_or_leave.to_f > 0
              if year_late_days >= 3
                base_money = base_money - (standard*0.6).round(2)
                calc_step.push_step("#{calc_step.step_notes.size + 1}. 12个日历月内迟到、早退#{year_late_days.to_i}次，当月基本工资项目扣发60%(#{(standard*0.6).round(2)})")
              elsif year_late_days == 2
                base_money = base_money - (standard*0.3).round(2)
                calc_step.push_step("#{calc_step.step_notes.size + 1}. 12个日历月内迟到、早退#{year_late_days.to_i}次，当月基本工资项目扣发30%(#{(standard*0.3).round(2)})")
              else
                base_money = base_money - (standard*0.1).round(2)
                calc_step.push_step("#{calc_step.step_notes.size + 1}. 迟到、早退1次的，当月基本工资项目扣发10%(#{(standard*0.1).round(2)})")
              end
            end

            # 旷工
            year_absenteeism_days = year_summaries.map(&:absenteeism).map(&:to_f).inject(&:+).to_f
            if summary.absenteeism.to_f > 0
              if year_absenteeism_days >= 2
                base_money = standard = global["minimum_wage"].round(2)
                calc_step.push_step("#{calc_step.step_notes.size + 1}. 12个日历月内累计旷工#{year_absenteeism_days}天，当月基础性工资项目按成都市最低工资标准计发(#{global["minimum_wage"].round(2)})")
              else
                base_money -= (standard*0.6).round(2)
                working_years_salary -= (working_years_salary*0.6).round(2)
                calc_step.push_step("#{calc_step.step_notes.size + 1}. 12个日历月内累计旷工#{year_absenteeism_days}天，扣发当月基本工资项目的" + 
                  "60%(#{(standard*0.6).round(2)})和工龄工资的60%(#{(working_years_salary*0.6).round(2)})")
              end
            end
          end
        end
        if base_money < 0
          calc_step.push_step("#{calc_step.step_notes.size + 1}. 实际基础薪酬为: #{base_money}, 因小于0, 将其置为0")
          base_money = 0
        end

        balance = base_money - base_standard

        if (!is_paiqian || channel == '空勤') && salary.employee.join_scal_date && salary.employee.join_scal_date.strftime("%Y-%m") == 
          compute_month && salary.employee.basic_salaries.select{|b| b.month == compute_month}.blank?
          if salary.employee.join_scal_date.day >= 15
            base_money += base_standard*0.5
            calc_step.push_step("#{calc_step.step_notes.size + 1}. 补发上月基础薪酬: #{base_standard*0.5}, 当月基础薪酬为: #{base_money}")
          else
            base_money += base_standard
            calc_step.push_step("#{calc_step.step_notes.size + 1}. 补发上月基础薪酬: #{base_standard}, 当月基础薪酬为: #{base_money}")
          end
          if %w(服务A 服务B).include?(channel)
            calc_step.push_step("#{calc_step.step_notes.size+1}. 员工通道为服务A或服务B，无工龄工资, 不补发")
          else
            working_years_salary += salary.working_years_salary.to_f
            calc_step.push_step("#{calc_step.step_notes.size+1}. 补发上月工龄工资: #{salary.working_years_salary.to_f}")
          end
        end
        total = base_money + working_years_salary

        values << [salary.employee.id, month, salary.employee.name, salary.employee.employee_no,
           salary.employee.department.full_name, master_position.name, salary.employee.channel_id, base_money,
           working_years_salary, notes, total, salaries_hash[salary.employee_id].try(:add_garnishee).to_f,
           salary.employee.salary_set_book, base_standard,
           balance, salaries_hash[salary.employee_id].try(:remark)]
        calc_values << [calc_step.employee_id, calc_step.month, calc_step.category, calc_step.step_notes, total]
      end

      CalcStep.where("month='#{month}' and category='basic_salary'").delete_all
      BasicSalary.where(month: month).delete_all

      CalcStep.import(CalcStep::COLUMNS, calc_values, validate: false)
      BasicSalary.import(COLUMNS, values, validate: false)

      if zero_keep_salaries.present?
        keep_salaries = KeepSalary.where("id in (?)", zero_keep_salaries)
        keep_salaries.update_all(total: 0)
        CalcStep.where(employee_id: keep_salaries.map(&:employee_id), category: 'keep_salary', month: month)
          .update_all("step_notes = concat(step_notes, '- \"员工因病或非因工受伤6个月以上的，按以下两项就高选择其一执行：1. 成都市最低工资标准的80%; 2. 本人月度工资收入（含基本工资项目、保留项目和股份工龄工资项目）的70%, 变更保留工资为0\"\n')")
      end
      true
    end
  end

  def self.deduct_basic_by_days(standard, position, summary, is_sick, month, category, calc_step, special_states = nil)
    sick_leave_work = summary.sick_leave_work_days.to_f + summary.ground_work_days.to_f
    personal_leave_work = summary.personal_leave_work_days.to_f
    sick_leave = summary.sick_leave.to_f + summary.sick_leave_injury.to_f + summary.sick_leave_nulliparous.to_f + summary.ground.to_f
    personal_leave = summary.personal_leave.to_f
    work_days = is_sick ? sick_leave_work : personal_leave_work
    days = is_sick ? sick_leave : personal_leave
    proportion = is_sick ? 0.1 : 1

    case position.schedule.try(:display_name)
    when '不定时工时制'
      calc_step.push_step("#{calc_step.step_notes.size + 1}. #{category}合计: 自然日#{days}天, 不定时工时制扣: 0元")
      return 0
    when '综合工时制'
      if sick_leave + personal_leave <= 5
        deduct_money = ((days/21.75)*standard*proportion).round(2)
        calc_step.push_step("#{calc_step.step_notes.size + 1}. #{category}自然日#{days}天, 病事假自然日合计小于5天及以下, 综合工时制扣: #{days}/21.75*档级标准*#{proportion} = #{deduct_money}")
        return deduct_money
      else
        naturals, works = summary.get_residue_work_days(1, is_sick ? 1 : 2, 5, special_states)
        deduct_money = (((naturals + works)/21.75)*standard*proportion).round(2)
        calc_step.push_step("#{calc_step.step_notes.size + 1}. #{category}自然日#{days}天, 病事假自然日合计大于5天, 综合工时制扣: (前5天含#{category}自然日: #{naturals} + 扣除前5天后含#{category}工作日: #{works})/21.75*档级标准*#{proportion} = #{deduct_money}")
        return deduct_money
      end
    else
      deduct_money = ((work_days/VacationRecord.month_working_days(month).to_f)*standard*proportion).round(2)
      calc_step.push_step("#{calc_step.step_notes.size + 1}. #{category}合计: 工作日#{work_days}天, 标准工时制扣: #{work_days}/月工作日*档级标准*#{proportion} = #{deduct_money}")
      return deduct_money
    end
  end

end

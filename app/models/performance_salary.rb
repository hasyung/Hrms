class PerformanceSalary < ActiveRecord::Base
  belongs_to :employee

  HOURS_FEE_STANDARD = {
    '一正' => 135,
    '一正级' => 135,
    '一副' => 110,
    '一副级' => 110,
    '二正' => 85,
    '二正级' => 85,
    '二副' => 55,
    '二副级' => 55,
    '主管' => 55
  }

  COLUMNS = %w(employee_no employee_name department_name position_name channel_id base_salary month 
    employee_id amount total add_garnishee salary_set_book result coefficient summary_deduct 
    performance_coeffic summary_days cardinal refund_fee notes remark department_distribute 
    department_reserved is_performance_deduct_days)

  class << self
    def cal_base_salary(month)
      PerformanceSalary.transaction do
        values, calc_values = [], []
        
        is_success, messages = AttendanceSummary.can_calc_salary?(month)
        return [is_success, messages] unless is_success

        perf_salaries = Salary.where("category like '%perf%'")
        fly_attendant_hour = Salary.find_by(category: 'fly_attendant_hour').form_data
        air_security_hour = Salary.find_by(category: 'air_security_hour').form_data
        service_c_2_perf = Salary.find_by(category: 'service_c_2_perf')
        manage_market_perf = Salary.find_by(category: 'manage_market_perf')
        market_leader_perf = Salary.find_by(category: 'market_leader_perf')
        global = Salary.find_by(category: 'global').form_data

        salaries_hash = PerformanceSalary.where(month: month).index_by(&:employee_id)

        SalaryPersonSetup.joins(:employee).includes(employee: [:department, :channel, :category, :attendance_summaries, 
          :master_positions, :punishments, :special_states, :performance_salaries]).each do |salary|
          channel = salary.employee.try(:channel).try(:display_name)
          diffent_months = nil
          is_performance_deduct_days = false
          if salary.employee.join_scal_date.present? && salary.employee.join_scal_date.year >= 
            Date.current.year - 1 && salary.employee.join_scal_date.year >= 2015
            diffent_months = Date.difference_in_months((month + '-01').to_date.end_of_month, VacationRecord.month_first_natural_day(salary.employee.join_scal_date))
          end
          
          next if salary.employee.department.full_name.split("-")[0] == '商旅公司' || salary.is_salary_special || 
            (diffent_months && diffent_months < 4)

          start_month = (month + '-01').to_date.beginning_of_month
          end_month = (month + '-01').to_date.end_of_month
          is_land_work = salary.employee.special_states.select{|s| (s.special_category == '空勤地面' || 
            s.special_category == '借调') && ((s.special_date_from < start_month && (s.special_date_to.blank? || 
            s.special_date_to > end_month)) || (s.special_date_from >= start_month && s.special_date_from <= end_month) || 
            (s.special_date_to && s.special_date_to >= start_month && s.special_date_to <= end_month))}.present?
          is_full_land_work = salary.employee.special_states.select{|s| (s.special_category == '空勤地面' || 
            s.special_category == '借调') && (s.special_date_from <= start_month && (s.special_date_to.blank? || 
            s.special_date_to >= end_month))}.present?

          calc_step = CalcStep.new employee_id: salary.employee_id, month: month, category: 'performance_salary'
          calc_step.push_step("===计算绩效基数===")
          master_position = salary.employee.try(:master_positions).try(:first)
          base_salary, standard, summary_deduct, summary_days, cardinal = 0, 0, 0, nil, 0
          notes, coefficient = '', 0
          is_deduct = true

          #主官
          if salary.employee.pcategory == '主官'
            calc_step.push_step("主官当月绩效基数为0，待人工编辑")
          else
            standard = base_salary = cardinal = salary.performance_money.to_f.round(2)
            summary = salary.employee.attendance_summaries.select{|s| s.summary_date == month}.first


           # if 员工通道==空勤 then
           #   if 员工分类 == 干部 then
           #       if 员工==整月空勤停飞上地面行政班 then
           #           员工同档级的标准作为绩效考核基数（扣考勤）进行正常分配算法
           #           小时费=员工分配结果
           #       if 员工==整月飞行 then
           #           员工的干部补贴作为绩效考核基数（补贴不做折算，作为基数后，不再按照正常基数一样做考勤、旷工、处分了，直接就是基数）进行正常分配算法
           #           小时费 = 实际小时费+考勤+旷工+处分+员工分配结果（此时再进行干部补贴的折算动作）+上浮下靠
           #       if 员工在综合状态 then
           #           员工同档级的标准作为绩效考核基数（扣考勤、旷工、处分）进行正常分配算法
           #           员工个人比例=（当月分配金额+留存部分分配金额）/月度绩效分配基数
           #           员工分配结果 <> 实飞小时费+考勤+旷工+处分+干部补贴（补贴要做折算）*个人比例
           #       if 员工分配结果 大 then
           #      小时费 = 员工分配结果+上浮下靠
           #       if 实飞小时费+考勤+旷工+处分+干部补贴（补贴要做折算）*个人比例 大 then
           #      小时费 = 实飞小时费+考勤+旷工+处分+干部补贴（补贴要做折算）*个人比例+上浮下靠
           #   if 员工分类= 员工 then
           #       if 员工==整月空勤停飞上地面行政班 then
           #           FC-2的标准作为基数（扣考勤、旷工、处分）进行正常分配算法
           #     小时费=员工分配结果
           #       if 员工=整月飞行 then
           #           正常算小时费
           #       if 员工在综合状态 then
           #           FC-2的标准作为基数（扣考勤）进行正常分配算法 <> 实飞小时费+考勤+旷工+处分
           #       if 员工分配结果 大 then
           #      小时费 = 员工分配结果+上浮下靠
           #       if 小时费 大 then
           #      小时费 = 实飞小时费+考勤+旷工+处分+上浮下靠

           # if 员工通道==飞行 then
           #   if 员工分类 == 干部 then
           #       if 员工==整月空勤停飞上地面行政班 then
           #           员工同档级的标准作为绩效考核基数（扣考勤、旷工、处分）进行正常分配算法
           #           小时费=员工分配结果+生育津贴+空勤灶
           #       if 员工==整月飞行 then
           #           正常算小时费
           #       if 员工在综合状态 then
           #           员工同档级的标准作为绩效考核基数（扣考勤、旷工、处分）进行正常分配算法
           #           员工分配结果 <> 实飞小时费+旷工+处分+干部补贴或前10名（都要做折算）
           #         if 员工分配结果 大 then
           #            小时费 = 员工分配结果+生育津贴+空勤灶
           #         if 实飞小时费+旷工+处分+干部补贴或前10名（都要做折算） 大 then
           #            小时费 = 实飞小时费+旷工+处分+干部补贴或前10名（都要做折算）+生育津贴+空勤灶

           #   if 员工分类= 员工 then
           #       if 员工==整月空勤停飞上地面行政班 then
           #           管理营销同年限的标准作为基数（扣考勤、旷工、处分）进行正常分配算法
           #     小时费=员工分配结果+生育津贴+空勤灶
           #       if 员工=整月飞行 then
           #           正常算小时费
           #       if 员工在综合状态 then
           #           管理营销同年限的标准作为基数（扣考勤、旷工、处分）进行正常分配算法 <> 实飞小时费+旷工+处分
           #       if 员工分配结果 大 then
           #      小时费 = 员工分配结果+生育津贴+空勤灶
           #       if 实飞小时费+旷工+处分 大 then
           #      小时费 = 实飞小时费+旷工+处分+生育津贴+空勤灶


            if %w(空勤 飞行).include?(channel)
              is_deduct = false unless is_full_land_work

              if %w(领导 干部).include?(salary.employee.category.try(:display_name)) || salary.technical_grade.present?
                if is_land_work
                  next if salary.performance_money.blank?
                  
                  calc_step.push_step("#{calc_step.step_notes.size}. 空勤地面行政班, 绩效基数为: #{standard}")
                else
                  next if channel == '飞行' || %w(空保大队 客舱服务部).include?(salary.employee.department.full_name.split('-').first)

                  airline = salary.try(:airline_hour_fee)
                  security = salary.try(:security_hour_fee)
                  type = airline_or_security?(salary, fly_attendant_hour, air_security_hour)

                  hour_money = type == 'true' ? fly_attendant_hour[airline] : air_security_hour[security]
                  standard = base_salary = cardinal = salary.leader_subsidy_hour.to_f*hour_money.to_f
                  step_note = "干部岗位薪酬等级:#{salary.leader_grade}, 绩效基数 = 干部补贴飞行时间:#{salary.leader_subsidy_hour.to_f}*小时费标准:#{hour_money}"
                  calc_step.push_step("#{calc_step.step_notes.size + 1}. " + step_note)
                end
              else
                diff_year = salary.employee.scal_working_years.to_i
                if channel == '空勤'
                  next unless is_land_work

                  c2_amount = service_c_2_perf.get_amount_by_column('C', diff_year)
                  if salary.employee.join_scal_date.present? && c2_amount == 0
                    diff_year = (Date.difference_in_months(end_month, salary.employee.join_scal_date)/12.0).round(2)
                    c2_amount = service_c_2_perf.get_amount_by_column('D', diff_year)
                  end
                  standard = base_salary = cardinal = c2_amount
                  calc_step.push_step("#{calc_step.step_notes.size}. 空勤上地面行政班, 工作时间: " + 
                    "#{diff_year}年服务 C-2 的合格绩效薪酬基数: #{standard}, 作为绩效基数")
                else
                  next unless is_land_work

                  market_amount = manage_market_perf.get_amount_by_column('C', diff_year)
                  if salary.employee.join_scal_date.present? && market_amount == 0
                    diff_year = (Date.difference_in_months(end_month, salary.employee.join_scal_date)/12.0).round(2)
                    market_amount = manage_market_perf.get_amount_by_column('D', diff_year)
                  end
                  standard = base_salary = cardinal = market_amount
                  calc_step.push_step("#{calc_step.step_notes.size}. 飞行上地面行政班, 工作时间: " + 
                    "#{diff_year}年管理营销的合格绩效薪酬基数: #{standard}, 作为绩效基数")
                end
              end
            else
              next if salary.performance_money.blank? || (channel != '服务B' && salary.performance_wage.blank?)
              calc_step.push_step("#{calc_step.step_notes.size}. 绩效工资: #{salary.performance_wage ? I18n.t('salary.category.' + salary.performance_wage) : '无'}, 档级: #{salary.performance_flag}, 绩效基数为: #{standard}")
            end

            salary_global = perf_salaries.select{|p| p.category == salary.performance_wage}.first.try(:form_data)
            if salary.performance_wage == 'service_tech_perf'
              salary_config = salary_global.values.inject([]){|a, v| a<<v.values}.flatten.inject([]){|a,v|a<<v.values}.flatten.select{|v|v["amount"]==salary.performance_money}.first
              return [false, "#{salary.employee.name} 个人薪酬绩效设置错误"] if salary_config.blank?
              coefficient = salary_config['rate']
            elsif %w(空勤 飞行 服务B).exclude?(channel)
              return [false, "#{salary.employee.name} 个人薪酬绩效设置错误"] if salary_global.blank? || salary_global["flags"].blank? || salary_global["flags"][salary.performance_flag].blank?
              coefficient = salary_global["flags"][salary.performance_flag]["rate"] if salary_global && salary.performance_flag
            end

            if is_deduct
            # 处分
              publishments = salary.employee.punishments.select{|p| p.genre == '处分' and (p.category == '警告' or 
                p.category == '记过' or p.category == '留用察看') and (p.start_date.present? and p.end_date.present?) and 
                ((p.start_date >= start_month and p.start_date <= end_month) or (p.end_date >= start_month and 
                p.end_date <= end_month) or (p.start_date < start_month and p.end_date > end_month))}
              if publishments.present?
                liuyong = publishments.select{|p| p.category == '留用察看'}.first
                if liuyong.present?
                  base_salary = 0
                  calc_step.push_step("#{calc_step.step_notes.size}. 留用察看处分期间，当月考核性收入全月扣发")
                  notes += "#{liuyong.start_date}到#{liuyong.end_date}受到留用察看处分"
                else
                  if salary_global or ['服务B', '飞行', '空勤'].include?(channel)
                    jiguo = publishments.select{|p| p.category == '记过'}.first
                    jinggao = publishments.select{|p| p.category == '警告'}.first
                    if jiguo.present?
                      if channel == '服务B'
                        base_salary -= (standard*0.1).round(2)
                        calc_step.push_step("#{calc_step.step_notes.size}. 记过处分期间，考核性收入下调10%发放(#{(standard*0.1).round(2)})")
                      elsif ['飞行', '空勤'].include?(channel)
                        standard_perf = nil
                        if %w(领导 干部).include?(salary.employee.category.try(:display_name))
                          standard_perf = market_leader_perf
                        else
                          if channel == '空勤'
                            standard_perf = service_c_2_perf
                          else
                            standard_perf = manage_market_perf
                          end
                        end

                        flags = standard_perf.form_data["flags"].map{|k, v| v["amount"]}
                        if flags.index(standard).to_i - 2 < 0
                          standard = base_salary = (flags[0]*0.5).round(2)
                          calc_step.push_step("#{calc_step.step_notes.size}. 记过处分期间，最低档则当月考核性收入按其档级标准的50%发放(#{base_salary})")
                        else
                          standard = base_salary = flags[flags.index(standard) - 2].round(2)
                          calc_step.push_step("#{calc_step.step_notes.size}. 记过处分期间，当月考核性收入下调两个档级的标准发放(#{base_salary})")
                        end
                      else
                        if salary.performance_flag
                          if salary.performance_flag.to_i - 2 < 1
                            standard = base_salary = (salary_global["flags"]["1"]["amount"]*0.5).round(2)
                            calc_step.push_step("#{calc_step.step_notes.size}. 记过处分期间，最低档则当月考核性收入按其档级标准的50%发放(#{base_salary})")
                          else
                            flag = salary.performance_flag.to_i - 2
                            standard = base_salary = salary_global["flags"][flag.to_s]["amount"].round(2)
                            calc_step.push_step("#{calc_step.step_notes.size}. 记过处分期间，当月考核性收入下调两个档级的标准发放(#{base_salary})")
                          end
                        end
                      end
                      notes += "#{jiguo.start_date}到#{jiguo.end_date}受到记过处分"
                    else
                      if channel == '服务B'
                        base_salary -= (standard*0.05).round(2)
                        calc_step.push_step("#{calc_step.step_notes.size}. 警告处分期间，考核性收入下调5%发放(#{(standard*0.05).round(2)})")
                      elsif ['飞行', '空勤'].include?(channel)
                        standard_perf = nil
                        if %w(领导 干部).include?(salary.employee.category.try(:display_name))
                          standard_perf = market_leader_perf
                        else
                          if channel == '空勤'
                            standard_perf = service_c_2_perf
                          else
                            standard_perf = manage_market_perf
                          end
                        end

                        flags = standard_perf.form_data["flags"].map{|k, v| v["amount"]}
                        if flags.index(standard).to_i - 1 < 0
                          standard = base_salary = (flags[0]*0.8).round(2)
                          calc_step.push_step("#{calc_step.step_notes.size}. 警告处分期间，最低档则当月考核性收入按其档级标准的80%发放(#{base_salary})")
                        else
                          standard = base_salary = flags[flags.index(standard) - 1].round(2)
                          calc_step.push_step("#{calc_step.step_notes.size}. 警告处分期间，当月考核性收入下调一个档级的标准发放(#{base_salary})")
                        end
                      else
                        if salary.performance_flag
                          if salary.performance_flag.to_i == 1
                            standard = base_salary = (salary_global["flags"]["1"]["amount"]*0.8).round(2)
                            calc_step.push_step("#{calc_step.step_notes.size}. 警告处分期间，最低档则当月考核性收入按其档级标准的80%发放(#{base_salary})")
                          else
                            flag = salary.performance_flag.to_i - 1
                            standard = base_salary = salary_global["flags"][flag.to_s]["amount"].round(2)
                            calc_step.push_step("#{calc_step.step_notes.size}. 警告处分期间，当月考核性收入下调一个档级的标准发放(#{base_salary})")
                          end
                        end
                      end
                      notes += "#{jinggao.start_date}到#{jinggao.end_date}受到警告处分"
                    end
                  end
                end
              end

              # 请假
              if summary.present?
                vacation_desc = salary.employee.get_vacation_desc(month).try(:values).try(:join, ", ").to_s
                notes += ', ' if notes.size > 0 && vacation_desc.size > 0
                notes += vacation_desc
                
                # 各项病假
                sick_leave = summary.sick_leave.to_f + summary.sick_leave_injury.to_f + summary.sick_leave_nulliparous.to_f
                if sick_leave > 0
                  deduct_money, deduct_days = deduct_performance_by_days(standard, master_position, summary, 1, month, '病假', calc_step)
                  summary_deduct += deduct_money
                  summary_days = summary_days.to_f + deduct_days
                end

                # 探亲假
                if (channel =~ /服务/).blank? && summary.home_leave.to_f > 0
                  deduct_money, deduct_days = deduct_performance_by_days(standard, master_position, summary, 3, month, '探亲假', calc_step)
                  summary_deduct += deduct_money
                  summary_days = summary_days.to_f + deduct_days
                end

                # 事假
                
                if summary.personal_leave.to_f > 0
                  last_summary = salary.employee.attendance_summaries.select{|s| s.summary_date == Date.parse(month + "-01").prev_month.strftime("%Y-%m")}.first
                  employee_performance = salary.employee.performance_salaries.select{|s| s.month == Date.parse(month + "-01").prev_month.strftime("%Y-%m")}.first
                  personal_leave_work_days = employee_performance.try(:is_performance_deduct_days) ? summary.personal_leave_work_days.to_f : summary.personal_leave_work_days.to_f + last_summary.try(:personal_leave_work_days).to_f
                  if personal_leave_work_days > 4
                    is_performance_deduct_days = true
                    summary_days = summary_days.to_f + summary.personal_leave.to_f
                    summary_deduct = base_salary if summary_deduct != base_salary
                    calc_step.push_step("#{calc_step.step_notes.size}. 考勤月度内事假天数累计4天(工作日)以上, 或连续两个考勤月度内事假天数累计4天(工作日)以上，月度考核收入全月扣发")
                  else
                    deduct_money, deduct_days = deduct_performance_by_days(standard, master_position, summary, 2, month, '事假', calc_step)
                    summary_deduct += deduct_money
                    summary_days = summary_days.to_f + deduct_days
                  end
                end

                # 迟到/早退
                year_summaries = salary.employee.attendance_summaries.select{|s| (s.summary_date + '-01').to_date <= (month + '-01').to_date && (s.summary_date + '-01').to_date > (month + '-01').to_date.last_year}
                year_late_days = year_summaries.map(&:late_or_leave).map(&:to_f).inject(&:+).to_f
                if summary.late_or_leave.to_f > 0 && year_late_days >= 3
                  summary_days = summary_days.to_f + summary.late_or_leave.to_f
                  summary_deduct = base_salary if summary_deduct != base_salary
                  calc_step.push_step("#{calc_step.step_notes.size}. 12个日历月内迟到、早退 #{year_late_days.to_i} 次，当月考核性收入全月扣发")
                end

                # 旷工
                year_absenteeism_days = year_summaries.map(&:absenteeism).map(&:to_f).inject(&:+).to_f
                if summary.absenteeism.to_f > 0 && year_absenteeism_days > 0
                  summary_deduct = base_salary if summary_deduct != base_salary
                  calc_step.push_step("#{calc_step.step_notes.size}. 12个日历月内累计旷工 #{year_absenteeism_days} 天，当月考核性收入全月扣发")
                end
              end

              base_salary = base_salary - summary_deduct
              if base_salary < 0
                calc_step.push_step("#{calc_step.step_notes.size + 1}. 实际绩效基数为: #{base_salary}, 因小于0, 将其置为0")
                base_salary = 0
              end
              calc_step.push_step("#{calc_step.step_notes.size}. 当月绩效基数总额为: #{base_salary}")
            end
          end
          values << [salary.employee.employee_no, salary.employee.name, salary.employee.department.full_name, 
            master_position.name, salary.employee.channel_id, base_salary, month, salary.employee.id, nil, nil, 
            salaries_hash[salary.employee_id].try(:add_garnishee).to_f, salary.employee.salary_set_book, '', 
            coefficient, summary_deduct, nil, summary_days, cardinal, 
            nil, notes, salaries_hash[salary.employee_id].try(:remark), nil, nil, is_performance_deduct_days]
          calc_values << [calc_step.employee_id, calc_step.month, calc_step.category, calc_step.step_notes, nil]
        end

        CalcStep.where("month='#{month}' and category='performance_salary'").delete_all
        PerformanceSalary.where(month: month).delete_all

        CalcStep.import(CalcStep::COLUMNS, calc_values, validate: false)
        PerformanceSalary.import(PerformanceSalary::COLUMNS, values, validate: false)
      end
    end

    def cal_salary(month)
      performance_salaries = PerformanceSalary.where(month: month)
      global = Salary.find_by(category: 'global').form_data["coefficient"][month]
      global ||= {}
      values, calc_values, performance_coeffic = [], [], 1
      
      PerformanceSalary.transaction do 
        performance_salaries.includes(employee: [:department, :channel, :hours_fees, :duty_rank, :category, 
          :salary_person_setup, :calc_steps, :special_states]).each do |salary|
          calc_step = salary.employee.calc_steps.select{|c| c.month == month && c.category == 'performance_salary'}.first
          calc_step = CalcStep.create employee_id: salary.employee_id, month: month, category: 'performance_salary' if calc_step.blank?
          calc_step.push_step("===计算绩效薪酬===") if calc_step.step_notes.index("===计算绩效薪酬===").blank?
          calc_step.step_notes.delete_if{|n| calc_step.step_notes.index(n) > calc_step.step_notes.index("===计算绩效薪酬===")}

          first_department = salary.employee.department.full_name.split("-")[0]
          amount = 0

          start_month = (month + '-01').to_date.beginning_of_month
          end_month = (month + '-01').to_date.end_of_month
          outer_company = salary.employee.special_states.select{|s| s.special_category == '借调' && s.special_location == '公司外' && 
            s.special_date_from <= start_month && (s.special_date_to.blank? || s.special_date_to >= end_month)}

          if outer_company.present?
            amount = salary.base_salary.to_f
            calc_step.push_step("#{calc_step.step_notes.size - 1}. 借调外单位，系数始终为1，不参与部门分配, 月绩效薪酬: #{amount}")
          elsif salary.employee.full_month_vacation?(month)
            amount = (salary.base_salary.to_f*global["perf_execute"].to_f).round(2)
            performance_coeffic = global["perf_execute"].to_f
            calc_step.push_step("#{calc_step.step_notes.size - 1}. 全月不在岗的，个人比例始终是1，执行系数按照公司标准(#{global["perf_execute"]}), 月绩效薪酬: #{amount}")
          elsif %w(文化传媒广告公司 校修中心).include?(first_department)
            amount = (salary.department_distribute.to_f + salary.department_reserved.to_f).round(2)
            calc_step.push_step("#{calc_step.step_notes.size - 1}. 文化传媒广告公司和校修员工,系数一直为1,当月绩效薪酬" + 
              "=当月分配金额(#{salary.department_distribute.to_f})+部门留存分配(#{salary.department_reserved.to_f})")
          elsif first_department == '商务委员会'
            if salary.employee.try(:channel).try(:display_name) == '服务A'
              amount = (salary.department_distribute.to_f + salary.department_reserved.to_f).round(2)
              calc_step.push_step("#{calc_step.step_notes.size - 1}. 商务委员会服务A通道的员工,系数一直为1,当月绩效薪酬" + 
                "=当月分配金额(#{salary.department_distribute.to_f})+部门留存分配(#{salary.department_reserved.to_f})")
            else
              amount = (salary.department_distribute.to_f*global["business_council"].to_f + salary.department_reserved.to_f).round(2)
              performance_coeffic = global["business_council"].to_f
              calc_step.push_step("#{calc_step.step_notes.size - 1}. 商务委员会的员工,系数一直为1,当月绩效薪酬" + 
                "=当月分配金额(#{salary.department_distribute.to_f})*商务委员会的月度效益指标系数(#{global["business_council"]})" + 
                "+部门留存分配(#{salary.department_reserved.to_f})")
            end
          elsif first_department == '物流部'
            if salary.employee.try(:channel).try(:display_name) == '服务B'
              amount = (salary.department_distribute.to_f*global["perf_execute"].to_f + salary.department_reserved.to_f).round(2)
              performance_coeffic = global["perf_execute"].to_f
              calc_step.push_step("#{calc_step.step_notes.size - 1}. 物流部服务B通道员工,使用公司月度效益指标系数,当月绩效薪酬" + 
                "=当月分配金额(#{salary.department_distribute.to_f})*公司月度效益指标系数(#{global["perf_execute"]})" + 
                "+部门留存分配(#{salary.department_reserved.to_f})")
            else
              amount = (salary.department_distribute.to_f*global["logistics"].to_f + salary.department_reserved.to_f).round(2)
              performance_coeffic = global["logistics"].to_f
              calc_step.push_step("#{calc_step.step_notes.size - 1}. 物流部员工,当月绩效薪酬" + 
                "=当月分配金额(#{salary.department_distribute.to_f})*物流部的月度效益指标系数(#{global["logistics"]})" + 
                "+部门留存分配(#{salary.department_reserved.to_f})")
            end
          elsif salary.employee.pcategory == '主官'
            amount = (salary.department_distribute.to_f*global["perf_execute"].to_f).round(2)
            performance_coeffic = global["perf_execute"].to_f
            calc_step.push_step("#{calc_step.step_notes.size - 1}. 主官,当月绩效薪酬" + 
              "=当月分配金额(#{salary.department_distribute.to_f})*公司月度效益指标系数(#{global["perf_execute"]})")
          elsif ['空勤', '飞行'].include?(salary.employee.try(:channel).try(:display_name))
            # 空勤无绩效考核收入
            calc_step.push_step("#{calc_step.step_notes.size - 1}. 飞行/空勤绩效考核收入在小时费中体现，此处为0")
          else
            amount = (salary.department_distribute.to_f*global["perf_execute"].to_f + salary.department_reserved.to_f).round(2)
            performance_coeffic = global["perf_execute"].to_f
            calc_step.push_step("#{calc_step.step_notes.size - 1}. 当月绩效薪酬" + 
                "=当月分配金额(#{salary.department_distribute.to_f})*公司当月效益指标系数(#{global["perf_execute"]})" + 
                "+部门留存分配(#{salary.department_reserved.to_f})")
          end
          refund_fee = salary.employee.salary_person_setup.refund_fee
          total = amount - refund_fee.to_f
          calc_step.push_step("#{calc_step.step_notes.size + 1}. 当月绩效薪酬(#{amount})" + 
            "-费用化报销(#{refund_fee})=绩效薪酬合计(#{total})")

          values << [salary.employee_no, salary.employee_name, salary.department_name, salary.position_name, 
            salary.channel_id, salary.base_salary, salary.month, salary.employee_id, amount, total, salary.add_garnishee, 
            salary.employee.salary_set_book, salary.result, salary.coefficient, salary.summary_deduct, 
            performance_coeffic, salary.summary_days, salary.cardinal, refund_fee, salary.notes, salary.remark, 
            salary.department_distribute, salary.department_reserved, salary.is_performance_deduct_days]
          calc_values << [calc_step.employee_id, calc_step.month, calc_step.category, calc_step.step_notes, total]
        end

        CalcStep.where("month='#{month}' and category='performance_salary'").delete_all
        PerformanceSalary.where(month: month).delete_all

        CalcStep.import(CalcStep::COLUMNS, calc_values, validate: false)
        PerformanceSalary.import(PerformanceSalary::COLUMNS, values, validate: false)
      end
    end

    def airline_or_security?(salary, fly_attendant_hour, air_security_hour)
      airline = salary.try(:airline_hour_fee)
      security = salary.try(:security_hour_fee)
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

    def deduct_performance_by_days(standard, position, summary, type_index, month, category, calc_step)
      sick_leave_work = summary.sick_leave_work_days.to_f
      personal_leave_work = summary.personal_leave_work_days.to_f
      home_leave_work = summary.home_leave_work_days.to_f
      sick_leave = summary.sick_leave.to_f + summary.sick_leave_injury.to_f + summary.sick_leave_nulliparous.to_f
      personal_leave = summary.personal_leave.to_f
      home_leave = summary.home_leave.to_f

      work_days = days = nil
      case type_index
      when 1
        work_days = sick_leave_work
        days = sick_leave
      when 2
        work_days = personal_leave_work
        days = personal_leave
      else
        work_days = home_leave_work
        days = home_leave
      end

      case position.schedule.try(:display_name)
      when '不定时工时制'
        calc_step.push_step("#{calc_step.step_notes.size + 1}. #{category}合计: 自然日#{days}天, 不定时工时制扣: 0元")
        return [0, days]
      when '综合工时制'
        if sick_leave + personal_leave + home_leave <= 5
          deduct_money = ((days/21.75)*standard).round(2)
          calc_step.push_step("#{calc_step.step_notes.size + 1}. #{category}自然日#{days}天, 病事探亲假自然日合计小于5天及以下, 综合工时制扣: #{days}/21.75*档级标准 = #{deduct_money}")
          return [deduct_money, days]
        else
          naturals, works = summary.get_residue_work_days(2, type_index)
          deduct_money = (((naturals + works)/21.75)*standard).round(2)
          calc_step.push_step("#{calc_step.step_notes.size + 1}. #{category}自然日#{days}天, 病事探亲假自然日合计大于5天, 综合工时制扣: (前5天含#{category}自然日: #{naturals} + 扣除前5天后含#{category}工作日: #{works})/21.75*档级标准 = #{deduct_money}")
          return [deduct_money, naturals + works]
        end
      else
        deduct_money = ((work_days/VacationRecord.month_working_days(month).to_f)*standard).round(2)
        calc_step.push_step("#{calc_step.step_notes.size + 1}. #{category}合计: 工作日#{work_days}天, 标准工时制扣: #{work_days}/月工作日*档级标准 = #{deduct_money}")
        return [deduct_money, work_days]
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

  end
end
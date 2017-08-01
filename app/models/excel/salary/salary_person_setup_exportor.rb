module Excel
  module Salary
    class SalaryPersonSetupExportor
      COLUMNS = ['员工姓名', '员工编号', '用工部门', '帐套', '员工账户', '基本工资', '工龄工资', '岗位工资保留', '业绩奖保留', '工龄工资保留', 
        '保底增幅', '地勤补贴保留', '生活补贴保留1', '生活补贴保留2', '09调资增加保留', '14公务用车保留', '14通信补贴保留', 
        '飞行员小时费', '空乘小时费', '空保小时费', '飞行驾驶技术津贴', '安检津贴', '安置补贴', 
        '班组长津贴', '航站管理津贴', '车勤补贴', '地勤补贴', '机务放行补贴', '试车津贴', '飞行安全荣誉津贴', '通讯补贴', 
        '公务车报销额度', '绩效工资', '高温补贴', '大厦补贴', '执勤补贴', '退休人员清洁费', '维修补贴', '后勤保障补贴', '值班工资', '部件放行补贴']

      class << self
        def export(salary_person_setups)
          book = Spreadsheet::Workbook.new
          sheet = book.create_worksheet

          sheet.row(0).default_format = Spreadsheet::Format.new :weight => :bold,
                                                                :size => 14,
                                                                :align => :center
          sheet.row(0).height = 25

          COLUMNS.each_with_index do |value, index|
            sheet.column(index).width = 15
            sheet.row(0).push(value)
          end

          salaries_allowance = ::Salary.find_by(category: 'allowance').form_data

          salary_person_setups.each_with_index do |setup, index|
            sheet.row(index + 1).height = 15

            sheet[index + 1, 0] = setup.employee.name
            sheet[index + 1, 1] = setup.employee.employee_no
            sheet[index + 1, 2] = setup.employee.department.full_name
            sheet[index + 1, 3] = setup.employee.set_book_info.try(:salary_category)
            sheet[index + 1, 4] = setup.employee.set_book_info.try(:employee_category)
            sheet[index + 1, 5] = setup.base_money
            sheet[index + 1, 6] = setup.working_years_salary || setup.employee.working_years_salary
            sheet[index + 1, 7] = setup.keep_position
            sheet[index + 1, 8] = setup.keep_performance
            sheet[index + 1, 9] = setup.keep_working_years
            sheet[index + 1, 10] = setup.keep_minimum_growth
            sheet[index + 1, 11] = setup.keep_land_allowance
            sheet[index + 1, 12] = setup.keep_life_1
            sheet[index + 1, 13] = setup.keep_life_2
            sheet[index + 1, 14] = setup.keep_adjustment_09
            sheet[index + 1, 15] = setup.keep_bus_14
            sheet[index + 1, 16] = setup.keep_communication_14
            sheet[index + 1, 17] = setup.fly_hour_money
            sheet[index + 1, 18] = setup.airline_hour_money
            sheet[index + 1, 19] = setup.security_hour_money
            # sheet[index + 1, 20] = setup.refund_fee
            sheet[index + 1, 20] = setup.flyer_science_money
            sheet[index + 1, 21] = salaries_allowance['security_subsidy'][setup.security_subsidy]
            sheet[index + 1, 22] = setup.placement_subsidy ? salaries_allowance['placement_subsidy'] : 0
            sheet[index + 1, 23] = salaries_allowance['leader_subsidy'][setup.leader_subsidy]
            sheet[index + 1, 24] = salaries_allowance['terminal_subsidy'][setup.terminal_subsidy]
            sheet[index + 1, 25] = setup.car_subsidy ? salaries_allowance['car_subsidy'] : 0
            sheet[index + 1, 26] = salaries_allowance['ground_subsidy'][setup.ground_subsidy]
            sheet[index + 1, 27] = salaries_allowance['machine_subsidy'][setup.machine_subsidy]
            sheet[index + 1, 28] = salaries_allowance['trial_subsidy'][setup.trial_subsidy]
            sheet[index + 1, 29] = salaries_allowance['honor_subsidy'][setup.honor_subsidy]
            sheet[index + 1, 30] = setup.communicate_allowance
            sheet[index + 1, 31] = setup.official_car
            sheet[index + 1, 32] = setup.performance_money
            sheet[index + 1, 33] = setup.temp_allowance
            sheet[index + 1, 34] = setup.building_subsidy
            sheet[index + 1, 35] = setup.on_duty_subsidy
            sheet[index + 1, 36] = setup.retiree_clean_fee
            sheet[index + 1, 37] = setup.maintain_subsidy
            sheet[index + 1, 38] = setup.logistical_support_subsidy ? salaries_allowance['logistical_support_subsidy'] : 0
            sheet[index + 1, 39] = setup.watch_subsidy ? salaries_allowance['watch_subsidy'] : 0
            sheet[index + 1, 40] = setup.part_permit_entry ? salaries_allowance['part_permit_entry'] : 0


          end unless salary_person_setups.blank?

          filename = CGI::escape("#{Time.now.to_i}薪酬个人设置.xls")
          book.write("#{Rails.root}/public/export/tmp/#{filename}")
          {
            path: "#{Rails.root}/public/export/tmp/#{filename}",
            filename: filename
          }
        end
      end
    end

  end
end
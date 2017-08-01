require 'spreadsheet'

module Excel
  module Salary
    class SubsidyImporter
      class << self
        def import(file_path)
          book = Spreadsheet.open(file_path)
          salaries_allowance = ::Salary.find_by(category: 'allowance').form_data
          sheet_hash = {leader_subsidy: "班组长", terminal_subsidy: "航站管理津贴", car_subsidy: "车勤补贴"}
          puts "$$$ 开始导入员工的班组长、航站管理津贴、车勤补贴设置，如果员工存在，但是薪酬个人设置不存在会自动创建空的"

          SalaryPersonSetup.transaction do
            sheet_hash.each do |key, sheet_name|
              book.sheet(sheet_name).each_with_index do |row, index|
                next if index == 0
                employee = Employee.find_by(employee_no: row[5])

                if employee
                  salary_person_setup = employee.salary_person_setup || employee.create_salary_person_setup
                  if key.to_s == "car_subsidy"
                    value = row[9] ? true : false
                    salary_person_setup.update_attribute(key, value)
                  else
                    value = salaries_allowance[key.to_s].key(row[9].to_i)
                    salary_person_setup.update_attribute(key, value)
                  end
                else
                  puts "#{index + 1} #{row[4]} #{row[5]}"
                end
              end
            end
          end
        end
      end
    end
  end
end

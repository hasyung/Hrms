require 'spreadsheet'

module Excel
  module Salary
    class SecuritySubsidyImportor

      def self.import(file_path)
        sheet = get_sheet(file_path)
        security_subsidy = ::Salary.find_by(category: 'allowance').form_data["security_subsidy"]

        error_names, error_count = [], 0

        puts "$$$ 开始导入员工的安检津贴设置，如果员工存在，但是薪酬个人设置不存在会自动创建空的"

        SalaryPersonSetup.transaction do
          sheet.each_with_index do |row, index|
            next if index == 0 || %w(科室领导 制表 合计).include?(row[0]) || row[0].blank?
            employee = Employee.find_by(employee_no: row[0])
            subsidy = security_subsidy.select{|k,v| v == row[6].to_i}

            if employee.blank? || subsidy.blank?
              row[1] += "  " if row[1].to_s.length == 2
              puts "#{index + 1} #{row[0]} #{row[1]}"
              error_count += 1
            else
              setup = employee.salary_person_setup || employee.build_salary_person_setup
              setup.security_subsidy = subsidy.keys.first
              setup.save
            end
          end
        end

        if error_count > 0
          puts "提示: 总共处理 #{sheet.count - 1} 行数据".yellow
          puts "警告: 有 #{error_count} 行导入失败，失败率 #{error_count * 100/(sheet.count - 1)}% \r\n\r\n".red
        end
      end

      private
      def self.get_sheet(file_path)
        book = Spreadsheet.open(file_path)
        book.worksheet 0
      end

    end
  end
end
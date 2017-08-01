require 'spreadsheet'

module Excel
  module Salary
    class TemperatureSubsidyImportor

      def self.import(file_path)
        sheet = get_sheet(file_path)
        array, count = [], 0

        puts "$$$ 开始导入员工的高温津贴设置"

        SalaryPersonSetup.transaction do
        	sheet.each_with_index do |row, index|
        		next if index == 0 || row[0].blank?
        		count += 1
            employee = Employee.unscoped.includes(:master_positions, :salary_person_setup).find_by(employee_no: row[0])

            if employee.blank? || employee.master_positions.blank? || row[17].blank?
            	array << "#{index + 1} #{row[0]} #{row[1]}"
            else
          		setup = employee.salary_person_setup || employee.build_salary_person_setup
              if employee.master_positions.first.temperature_amount != row[17].to_i
            		setup.update(temp_allowance: row[17].to_i)
              else
                setup.update(temp_allowance: nil)
            	end
            end
        	end
        end

        if array.size > 0
          puts array.join("\r\n").red
          puts "警告:有 #{array.size} 行导入失败，失败率 #{(array.size*100.0/count).round(2)}% \r\n\r\n".red
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
require 'spreadsheet'

# Excel::Salary::PerformanceSpecialImportor.import("文件路径")

module Excel
	module Salary
	  class PerformanceSpecialImportor
	  	BASIC_KEY_HASH = {
      	"分队长"  => 'captain',
        "副分队长"  => 'vice_captain',
        "机械师"  => 'machinist',
        "工程师"  => 'engineer'
      }

	    def self.import(file_path)
	      puts "准备导入机务特殊人员的绩效工资，如果员工存在，但是薪酬个人设置不存在会自动创建空的"
        array, count = [], 0
        sheet = get_sheet(file_path)
        service_tech_perf = ::Salary.find_by(category: "service_tech_perf").form_data

        ActiveRecord::Base.transaction do
          sheet.each_with_index do |row, index|
            next if index == 0 || row[1].blank?
            count += 1
            employee = Employee.unscoped.includes(:salary_person_setup).find_by(employee_no: row[1])

            if employee.present? && row[8].present?
              setup = employee.salary_person_setup || employee.build_salary_person_setup

              setup.performance_wage = 'service_tech_perf'
              if row[8].split('-')[0] == '工程师'
              	setup.technical_category = 'engineer'
              else
              	setup.technical_category = 'airbus'
              end
            	setup.performance_position = BASIC_KEY_HASH[row[8].split('-')[0]]

              case row[8].split('-')[1].to_i
              when 1
              	setup.performance_channel = 'A'
              when 2
              	setup.performance_channel = 'B'
              when 3
              	setup.performance_channel = 'C'
              when 4
              	setup.performance_channel = 'D'
              when 5
              	setup.performance_channel = 'E'
              when 6
              	setup.performance_channel = 'F'
              end

              if setup.performance_position
	              setup.performance_money = service_tech_perf[setup.technical_category][setup.performance_position][setup.performance_channel]["amount"]
	              setup.save
	            else
	            	array << "#{index + 1} #{row[0]} #{row[1]}"
	            end
            else
              array << "#{index + 1} #{row[0]} #{row[1]}"
            end
          end

          if array.size > 0
            puts array.join("\r\n").red
            puts "警告:有 #{array.size} 行导入失败，失败率 #{(array.size*100.0/count).round(2)}% \r\n\r\n".red
          end
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
 require 'spreadsheet'

module Excel
  	class VacationRecordImportor

    	def self.import(file_path)
    		book = Spreadsheet.open(file_path)
      		sheet = book.worksheet 0
      		ActiveRecord::Base.transaction do
      			sheet.each_with_index do |row, index|
      				next if row[0] == "员工编号"
      				employee = Employee.find_by(employee_no:row[0])
      				if employee.blank?
      					raise "人员#{row[1]}不存在"
      				end
      				vacation_record = VacationRecord.find_by(record_type:"年假",employee_id:employee.id,year:row[3].to_i)
      				if vacation_record.blank?

      					VacationRecord.create!(record_type:"年假",employee_id:employee.id,year:row[3].to_i,days:row[2].to_f)
      				else

      					# vacation_record.days = vacation_record.days.to_f + row[2].to_f
      					# vacation_record.save
                vacation_record.update(days: row[2].to_f)
      				end
      			end
      		end
    	end
	end
end
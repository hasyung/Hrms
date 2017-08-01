module Excel
	class WorkShiftsImportor
		attr_reader :errors
		def initialize(path)
			@sheet = Spreadsheet.open(path).worksheet(0)
			@errors = []
		end

		def parse_data
			@sheet.each_with_index do |row, index|
				if index == 0 && row[0] != "员工代码" && row[6] != "班制" 
					@errors << "表格格式错误！" 
					break
				end
				next if index == 0
				employee = Employee.find_by(employee_no: row[0])
				@errors << "第#{index+1}行，人员不存在。" if employee.nil?
			end

			return self if @errors.size > 0

			@sheet.each_with_index do |row, index|
				next if index == 0
				unless ["行政班","两班倒","三班倒","四班倒","空勤"].include?row[6].strip
					@errors << "第#{index+1}行，班制类型填写错误。"
				end
			end

			self
		end

		def import
			ActiveRecord::Base.transaction do
				@sheet.each_with_index do |row, index|
					begin
						next if index == 0
						employee = Employee.find_by(employee_no: row[0])
						next if employee.nil?
						work_shifts = WorkShift.where(employee_id: employee.id, end_time: nil)
						hash = {
							employee_id: employee.id,
							employee_no: employee.employee_no,
							work_shifts: row[6].strip,
							start_time:  Time.now
						}
						if work_shifts.present?
							work_shifts.update_all(end_time: Time.now)
						end
						WorkShift.create(hash)
					rescue Exception => e
						errors << "第#{index+1}行导入失败！"
						raise e
					end
				end
			end
		end
	end
end
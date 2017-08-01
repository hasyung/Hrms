require 'spreadsheet'
module Excel
	class EmployeeTechnicalFirstImport
		def self.import(file_path)
			puts '开始导入人员技术等级'
			@array = []
	    	@count = 0
	    	@errors = []
	    	technical = ''
	    	sheet = get_sheet(file_path)
	    	ActiveRecord::Base.transaction do
	    		Employee.all.each {|employee| 
	    			employee.technical = nil 
	    			employee.save
	    		}
	    		sheet.each_with_index do |row, index|
	    			next if row[1] == "C_NAME"
	    			employee = Employee.find_by(employee_no:row[6])
	    			if employee.blank?
	    				@errors << "人员#{row[1]}不存在"
	    				@count += 1
	    				next
	    			end
	    			# Employee.update(employee.id,technical:nil)
	    			if employee.technical.nil?
	    				technical = "#{row[3]}:#{row[5]}"
	    			else
	    				technical = employee.technical+", #{row[3]}:#{row[5]}"
	    			end
					# Employee.update(employee.id,technical:technical)
					employee.technical = technical
					employee.save
					@count += 1
		    	end
	    	end
	    	if @errors.size > 0
		        puts @errors.join("\r\n").red
		        puts "提示: 总共处理 #{@count} 行数据".yellow
		        puts "警告: 有 #{@errors.size} 行导入失败，失败率 #{(@errors.size * 100.0/@count).round(2)}% \r\n\r\n".red
		    end
		end

		private
		def self.get_sheet(file_path)
	      	book = Spreadsheet.open(file_path)
	      	book.worksheet 0
	    end
	end
end
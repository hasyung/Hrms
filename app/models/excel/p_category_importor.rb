require 'spreadsheet'

module Excel
	class PCategoryImportor
		def self.import(file_path)
		@array = []
    	@count = 0
    	@errors = []
    	sheet = get_sheet(file_path)

    	puts "$$$ 开始导入人员的职级"

    	ActiveRecord::Base.transaction do
    		sheet.each_with_index do |row, index|
    			next if row[0] == "人员编码"
    			employee = Employee.find_by(employee_no:row[0])
    			if employee.blank?
    				@errors << "人员#{row[1]}不存在"
    				@count += 1
    				next
    			end
                pcategory = row[6]
                if pcategory == "部门主官"
                    pcategory = "主官"
                end
    		    Employee.update(employee.id,pcategory:pcategory)

            	if @errors.size > 0
                puts @errors.join("\r\n").red
                puts "提示: 总共处理 #{@count} 行数据".yellow
                puts "警告: 有 #{@errors.size} 行导入失败，失败率 #{(@errors.size * 100.0/@count).round(2)}% \r\n\r\n".red
                end
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
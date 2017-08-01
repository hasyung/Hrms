require 'spreadsheet'

module Excel
	class EmployeeStarImportor
	    attr_accessor :errors
	    def initialize path
	      @sheet = Spreadsheet.open(path)
	      @errors = []
	    end

	    def import
	    	ActiveRecord::Base.transaction do
		    	@sheet.each_with_index do |row, index|
		    		next if index == 0
		    		employee = Employee.find_by(employee_no: row[0])
		    		employee.update(star: row[2])
		    	end
		    end
	    end
	    
	    def vaild_format
	    	@sheet.each_with_index do |row, index|
	    		next if index == 0
	    		employee = Employee.find_by(employee_no: row[0])
	    		if employee.nil?
	    			@errors << "第#{index+1}行，人员#{row[1]}不存在"
	    			return false
	    		end
	    		if row[0].nil? || row[1].nil? || row[2].nil?
	    			@errors << "第#{index+1}行，信息填写不完整！"
	    			return false
	    		end
	    	end
	    	return true
	    end
	end
end

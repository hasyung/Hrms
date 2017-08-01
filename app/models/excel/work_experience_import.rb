require 'spreadsheet'

module Excel
  class WorkExperienceImport
  	attr_accessor :errors

  	COLUMNS = %w(company department position job_desc job_title start_date end_date witness category employee_id employee_category)

	def initialize path
		@sheet = Spreadsheet.open(path).worksheet(0)
		@errors = []
	end

	def parse_data
		unless vaild_format
			return @errors
		end
	end
    
    def import
    	# ActiveRecord::Base.transaction do
    	# 	employee_nos = @sheet.inject([]) do |result, row|
    	# 		result << row[9]
    	# 		result
    	# 	end.uniq
    	# 	employee_nos.each_with_index do |employee_no, index|
    	# 		next if index == 0
    	# 		Employee.find_by(employee_no:employee_no).work_experiences.where("end_date!='至今'").destroy_all
    	# 	end
	    # 	@sheet.each_with_index do |row, index|
	    # 		raise ActiveRecord::Rollback if @errors.present?
	    # 		next if index == 0
	    # 		hash = {
	    # 			company: row[0],
	    # 			department: row[1],
	    # 			position: row[2].gsub(/（|）/, '（' => '(', '）' => ')'),
	    # 			job_desc: row[3],
	    # 			job_title: row[4],
	    # 			start_date: row[5],
	    # 			end_date: row[6],
	    # 			witness: row[7],
	    # 			category: (row[8] == "入司前" ? "before" : "after"),
	    # 			employee_id: Employee.find_by(employee_no: row[9]).id,
	    # 			employee_category: row[11]
	    # 		}
	    # 		employee = Employee.find_by(employee_no: row[9])
	    # 		if row[6] != "至今"
	    # 			create_experience(hash)
	    # 		else
		   #  		work_experiences = employee.work_experiences.where(end_date: "至今").inject([]) do |result, work_experience|
		   #  			position = work_experience.position.gsub(/（|）/, '（' => '(', '）' => ')').split(/[(|)]/).compact.select{|a| a.size != 0}
		   #  			position << work_experience.department
		   #  			# position << work_experience.start_date
		   #  			result << position
		   #  			result
		   #  		end
		   #  		sheet_work_experience = row[2].gsub(/（|）/, '（' => '(', '）' => ')').split(/[(|)]/).compact.select{|a| a.size != 0}
		   #  		sheet_work_experience << row[1]
		   #  		# sheet_work_experience << row[5]
		   #  		if work_experiences.include?(sheet_work_experience)
		   #  			experience = employee.work_experiences.where(department: row[1], position: row[2].gsub(/（|）/, '（' => '(', '）' => ')'))
		   #  			if experience.map(&:start_date).include?(row[5])
		   #  				experience.select{|e| e.start_date == row[5]}.first.update(hash)
		   #  			else
		   #  				@errors << "第#{index+1}行，开始时间填写错误！"
		   #  				next
		   #  			end
		   #  		else
		   #  			position_names = employee.employee_positions.where(category:row[2].gsub(/（|）/, '（' => '(', '）' => ')').split(/[(|)]/).last).inject([]) do |result, employee_position|
		   #  				result << (employee_position.position.name.gsub(/（|）/, '（' => '(', '）' => ')').split(/[(|)]/).compact.select{|a| a.size != 0 &&  a != "主职" && a != "兼职" && a != "代理" && a != "临时主持"} << employee_position.position.department.full_name)
		   #  				result
		   #  			end
		   #  			if position_names.include?(row[2].gsub(/（|）/, '（' => '(', '）' => ')').split(/[(|)]/).compact.select{|a| a.size != 0 &&  a != "主职" && a != "兼职" && a != "代理" && a != "临时主持"} << row[1])
		   #  				create_experience(hash)
		   #  			else
		   #  				@errors << "第#{index+1}行，人员与部门岗位不对应！"
		   #  			end
		   #  		end
		   #  	end
	    # 	end
	    # end

	  	

	  	ActiveRecord::Base.transaction do 
	  		employee_nos = []
	  		experience_ids = []
	  		values = []
	  		@sheet.each_with_index do |row, index|
	  			next if index == 0
	  			employee_nos << row[9]
	  			employee = Employee.find_by(employee_no: row[9])
	  			experience_ids << employee.work_experiences.map(&:id)
	  			values << [
	    			row[0],
	    			row[1],
	    			row[2].gsub(/（|）/, '（' => '(', '）' => ')'),
	    			row[3],
	    			row[4],
	    			row[5],
	    			row[6],
	    			row[7],
	    			(row[8] == "入司前" ? "before" : "after"),
	    			employee.id,
	    			row[11]
	    		]
	  		end
	  		Employee::WorkExperience.where(id:experience_ids.flatten).delete_all
	  		Employee::WorkExperience.skip_callback(:create, :before, :set_category)
			Employee::WorkExperience.import(COLUMNS, values, validate: false)
			Employee::WorkExperience.set_callback(:create, :before, :set_category)
	    end
	    	
    end

    def vaild_format
    	@sheet.each_with_index do |row, index|
    		next if index == 0
    		row.each_with_index do |column, row_index|
    			if [0,1,2,5,6,8,9,10,11].include?(row_index) && column.nil?
	    			@errors << "第#{index+1}行信息填写不完整" 
	    			return false
	    		end
	    		if row[8] != "入司前" && row[8] != "入司后"
	    			@errors << "第#{index+1}行 入职前后一列 填写错误"
	    			return false
	    		end
	    		if row[11] != "领导" && row[11] != "干部" && row[11] != "员工"
	    			@errors << "第#{index+1}行 人员分类 填写错误"
	    			return false
	    		end
	    		if row[5].split("-").size != 3
	    			@errors << "第#{index+1}行 时间格式错误, 时间格式必须以'-'分割"
	    			return false
	    		end
	    		if row[6].nil?
	    			@errors << "结束日期不能为空，填写“至今”或具体时间！"
	    			return false
	    		end
	    		if !(row[6] == "至今" || row[6].split("-").size == 3)
	    			@errors << "第#{index+1}行 时间格式错误, 时间格式必须以'-'分割"
	    			return false
	    		end
    		end
    		if Employee.find_by(employee_no: row[9]).nil?
    			@errors << "第#{index+1}行 人员#{row[10]}不存在"
    			return false
    		end
    	end
    	return true
    end

    #获取人员所在岗位名称,一个人可能有多个同类型岗位
    def employee_position_names(employee, type)
    	position_name = []
    	employee.employee_positions.select{|e| e.category==type}.each do |employee_position|
    		position_name << employee_position.position.name
    	end
    	position_name
    end

    def create_experience(hash)
    	Employee::WorkExperience.skip_callback(:create, :before, :set_category)
		Employee::WorkExperience.create(hash)
		Employee::WorkExperience.set_callback(:create, :before, :set_category)
    end
  end
end
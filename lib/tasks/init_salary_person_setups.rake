require 'spreadsheet'

namespace :init do
  	desc "hours_fee others for salary_person_setups"
  	task hours_fee_others_for_salary_person_setups: :environment do
	    puts '开始进行导入....'
	    file_path = "#{Rails.root}/public/小时费档级_20160630_.xls"
	    book = Spreadsheet.open file_path
	    sheet_one = book.worksheet 0
	    sheet_two = book.worksheet 1
	    sheet_three = book.worksheet 2
	    count = 0
	    errors = []
	    ActiveRecord::Base.transaction do
		    sheet_one.each_with_index do |row, index|
		    	next if row[0] == "人员编码"
		    	employee = Employee.find_by(employee_no:row[0])
		    	if employee.blank?
		    		errors << "人员#{row[1]}不存在"
		    		next
		    	end
		    	salary_person_setup = SalaryPersonSetup.find_by(employee_id:employee.id)
		    	salary_person_setup.lower_limit_hour = row[6].to_i
		    	salary_person_setup.limit_leader = 1 unless row[5].nil?
		    	salary_person_setup.leader_subsidy_hour = row[7].to_i unless row[7].nil?
		    	salary_person_setup.technical_grade = row[8] unless row[8].nil?
				salary_person_setup.save
				count += 1
		    end
		  	sheet_two.each_with_index do |row, index|
		  		next if row[0] == "人员编码"
		    	employee = Employee.find_by(employee_no:row[0])
		    	if employee.blank?
		    		errors << "人员#{row[1]}不存在"
		    		next
		    	end
		    	salary_person_setup = SalaryPersonSetup.find_by(employee_id:employee.id)
		    	salary_person_setup.lower_limit_hour = row[6].to_i unless row[6].nil?
		    	salary_person_setup.leader_subsidy_hour = row[7].to_i unless row[7].nil?
		    	salary_person_setup.technical_grade = row[8] unless row[8].nil?
		    	salary_person_setup.save
		    	count += 1
		  	end
		  	sheet_three.each_with_index do |row, index|
		  		next if row[1] == "人员编码"
		    	employee = Employee.find_by(employee_no:row[1])
		    	if employee.blank?
		    		errors << "人员#{row[0]}不存在"
		    		next
		    	end
		    	salary_person_setup = SalaryPersonSetup.find_by(employee_id:employee.id)
		    	salary_person_setup.lower_limit_hour = row[6].to_i unless row[6].nil?
		    	salary_person_setup.leader_subsidy_hour = row[7].to_i unless row[7].nil?
		    	salary_person_setup.technical_grade = row[8] unless row[8].nil?
		    	salary_person_setup.save
		    	count += 1
		  	end
		end
		if errors.size > 0
			puts errors.join("\r\n").red
		    puts "提示: 总共处理 #{count} 行数据".yellow
		    puts "警告: 有 #{errors.size} 行导入失败，失败率 #{(errors.size * 100.0/count).round(2)}% \r\n\r\n".red
		end
    end







end
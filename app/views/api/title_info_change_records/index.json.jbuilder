json.title_info_change_records @title_info_change_records do |title_info_change_record|
	employee = Employee.find_by(id:title_info_change_record.employee_id)
	json.id               				title_info_change_record.id
	json.employee_name			  				employee.name
	json.employee_id	  				title_info_change_record.employee_id
	json.employee_no 					employee.employee_no
	json.prev_job_title 				title_info_change_record.prev_job_title
	json.prev_job_title_degree_id		title_info_change_record.prev_job_title_degree_id
	json.prev_technical_duty			title_info_change_record.prev_technical_duty
	json.prev_file_no					title_info_change_record.prev_file_no
	json.job_title 						title_info_change_record.job_title
	json.job_title_degree_id 			title_info_change_record.job_title_degree_id
	json.technical_duty 				title_info_change_record.technical_duty
	json.file_no 						title_info_change_record.file_no
	json.change_date 					title_info_change_record.change_date

	json.department do
	    json.id     employee.department_id
	    json.name   employee.department.full_name
	end

	  json.position do
	    json.name EmployeePosition.full_position_name(employee.employee_positions)
	end
end

json.partial! 'shared/page_basic'
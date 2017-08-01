json.workflows @cvis do |cvi|
  json.employee_id cvi.employee_id
  json.employee_no cvi.employee_no
  json.employee_name cvi.employee_name
  json.vacation_dates cvi.vacation_dates
  json.vacation_days cvi.vacation_days
  json.name cvi.leave_type
  if cvi.is_checking
  	json.state "已审批"
  else
  	json.state "未审批"
  end
  json.department_name Department.includes(:employees).references(:employees).find_by('employees.id=?',cvi.employee_id).name
  json.position_name Position.includes(:employee_positions).references(:employee_positions).find_by('employee_positions.employee_id=?',cvi.employee_id).name

end

json.partial! 'shared/page_basic'

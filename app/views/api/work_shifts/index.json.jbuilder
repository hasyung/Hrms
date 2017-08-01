json.work_shifts @work_shifts do |item|
  json.id          item.id
  json.employee_id item.employee.id
  json.employee_no item.employee.employee_no
  json.employee_name item.employee.name
  json.position_name EmployeePosition.full_position_name(item.employee.employee_positions)
 

  json.work_shifts item.work_shifts
  json.start_time item.start_time
  json.end_time item.end_time
  json.create_time item.created_at
  json.update_time item.updated_at

  json.department do
    json.id     item.employee.department_id
    json.name   item.employee.department.full_name
  end
end

json.partial! 'shared/page_basic'
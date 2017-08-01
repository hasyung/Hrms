json.employees @employees do |employee|
  master_position = employee.master_positions.first

  json.id                    employee.id
  json.name                  employee.name
  json.gender_id             employee.gender_id
  json.employee_no           employee.employee_no
  json.join_scal_date        employee.join_scal_date
  json.start_internship_date employee.start_internship_date
  json.labor_relation_id     employee.labor_relation_id
  json.identity_no           employee.identity_no
  json.location              employee.location
  json.channel_id            employee.channel_id  || master_position.channel_id
  json.category_id           employee.category_id || master_position.category_id
  json.birthday              employee.birthday
  json.offset_days           employee.offset_days
  json.vacations      employee.vacation_summary

  json.department do
    json.id     employee.department_id
    json.name   employee.department.full_name
  end

  json.position do
    json.name EmployeePosition.full_position_name(employee.employee_positions)
  end
end

json.partial! 'shared/page_basic'

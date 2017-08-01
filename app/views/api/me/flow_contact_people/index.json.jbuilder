json.flow_contact_people @employees do |employee|
  json.id                employee.id
  json.name              employee.name
  json.department_name   employee.department.name
  json.position_name     EmployeePosition.full_position_name(employee.employee_positions)
end

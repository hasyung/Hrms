json.employees @employees do |employee|
  json.id                  employee.id
  json.name                employee.name
  json.employee_no         employee.employee_no
  json.gender_id           employee.gender_id
  json.position do
    json.id employee.master_positions.first.id
    json.name employee.master_positions.first.name
  end
  json.department do
    json.id employee.department.id
    json.name employee.department.full_name
  end
end
json.employees @employee_positions do |employee_position|
  json.id employee_position.employee.id
  json.employee do
    json.name employee_position.employee.name
  end
  json.employee_no employee_position.employee.employee_no
  json.start_date employee_position.start_date
  json.end_date employee_position.end_date
  json.remark employee_position.remark
end
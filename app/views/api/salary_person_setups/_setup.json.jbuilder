json.id salary.id
json.employee_id salary.employee_id
json.employee_no salary.employee.employee_no
json.employee_name salary.employee.name
json.position_name salary.employee.master_positions.first.name
json.category_id employee.category_id
json.channel_id employee.channel_id
json.labor_relation_id employee.labor_relation_id
json.location employee.location
json.is_salary_special salary.is_salary_special
json.department do
  json.id salary.employee.department.id
  json.name salary.employee.department.full_name
end

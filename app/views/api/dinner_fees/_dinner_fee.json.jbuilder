json.id dinner_fee.id
json.employee_id dinner_fee.employee_id
json.employee_no dinner_fee.employee_no
json.employee_name dinner_fee.employee_name
json.shifts_type dinner_fee.shifts_type
json.area dinner_fee.area
json.card_number dinner_fee.card_number
json.card_amount dinner_fee.card_amount.to_f
json.working_fee dinner_fee.working_fee.to_f
json.backup_fee dinner_fee.backup_fee.to_f
json.month dinner_fee.month

if dinner_fee.employee
  json.department_name dinner_fee.employee.department.full_name
  json.position_name dinner_fee.employee.master_position.name
  json.location dinner_fee.employee.location
end

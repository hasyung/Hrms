json.id dinner_settle.id
json.employee_id dinner_settle.employee_id
json.employee_no dinner_settle.employee_no
json.employee_name dinner_settle.employee_name
json.shifts_type dinner_settle.shifts_type
json.area dinner_settle.area
json.card_number dinner_settle.card_number
json.card_amount dinner_settle.card_amount.to_f
json.working_fee dinner_settle.working_fee.to_f
json.backup_fee dinner_settle.backup_fee.to_f
json.month dinner_settle.month
json.deficit_amount dinner_settle.deficit_amount.to_f
json.location dinner_settle.location
json.total dinner_settle.total.to_f

if dinner_settle.employee
  json.department_name dinner_settle.employee.department.full_name
  json.position_name dinner_settle.employee.master_position.name
  json.location dinner_settle.employee.location
end
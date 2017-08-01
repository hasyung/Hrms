json.id night_fee.id
json.employee_id night_fee.employee_id
json.employee_no night_fee.employee_no
json.employee_name night_fee.employee_name
json.shifts_type night_fee.shifts_type
json.location night_fee.location
json.night_number night_fee.night_number
json.notes night_fee.notes
json.subsidy night_fee.subsidy.to_f
json.amount night_fee.amount.to_f
json.is_invalid night_fee.is_invalid
json.flag night_fee.flag

if night_fee.employee
  json.department_name night_fee.employee.department.full_name
  json.position_name night_fee.employee.master_position.name
  # json.location night_fee.employee.location
end

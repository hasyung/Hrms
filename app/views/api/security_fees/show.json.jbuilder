json.security_fee do
  json.id @security_fee.id
  json.employee_no @security_fee.employee_no
  json.employee_name @security_fee.employee_name
  json.department_name @security_fee.department_name
  json.position_name @security_fee.position_name
  json.fee format("%.2f" , @security_fee.fee || 0)
  json.add_garnishee format("%.2f" , @security_fee.add_garnishee || 0)
  json.remark @security_fee.remark
  json.month @security_fee.month
  json.employee_id @security_fee.employee_id
  json.notes @security_fee.notes
  json.channel_id @security_fee.employee.channel_id
  json.category 'security_fee'
end
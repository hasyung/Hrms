json.hours_fee do
  json.id @hours_fee.id
  json.employee_no @hours_fee.employee_no
  json.employee_name @hours_fee.employee_name
  json.department_name @hours_fee.department_name
  json.position_name @hours_fee.position_name
  json.channel_id @hours_fee.channel_id
  json.fly_hours format("%.2f" , @hours_fee.fly_hours || 0)
  json.fly_fee format("%.2f", @hours_fee.fly_fee || 0)
  json.airline_fee format("%.2f", @hours_fee.airline_fee || 0)
  json.add_garnishee format("%.2f" , @hours_fee.add_garnishee || 0)
  json.remark @hours_fee.remark
  json.notes @hours_fee.notes
  json.month @hours_fee.month
  json.employee_id @hours_fee.employee_id
  json.category HoursFee::CATEGORIES[@hours_fee.hours_fee_category]
  json.fertility_allowance @hours_fee.fertility_allowance
  json.ground_subsidy @hours_fee.ground_subsidy
end
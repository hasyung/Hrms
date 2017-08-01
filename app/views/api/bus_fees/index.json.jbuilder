json.bus_fees @bus_fees do |bus_fee|
  json.id bus_fee.id
  json.employee_no bus_fee.employee_no
  json.employee_name bus_fee.employee_name
  json.department_name bus_fee.department_name
  json.position_name bus_fee.position_name
  json.fee format("%.2f" , bus_fee.fee || 0)
  json.add_garnishee format("%.2f" , bus_fee.add_garnishee || 0)
  json.remark bus_fee.remark
  json.month bus_fee.month
  json.employee_id bus_fee.employee_id
end

json.partial! 'shared/page_basic'
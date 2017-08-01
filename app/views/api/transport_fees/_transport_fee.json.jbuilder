json.id transport_fee.id
json.employee_id transport_fee.employee_id
json.employee_name transport_fee.employee_name
json.employee_no transport_fee.employee_no
json.channel_id transport_fee.channel_id
json.department_name transport_fee.department_name
json.position_name transport_fee.position_name
json.month transport_fee.month
json.notes transport_fee.notes
json.remark transport_fee.remark
json.amount format("%.2f" , transport_fee.amount || 0)
json.add_garnishee format("%.2f" , transport_fee.add_garnishee || 0)
json.category 'transport_fee'
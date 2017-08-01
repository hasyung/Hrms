json.id allowance.id
json.employee_id allowance.employee_id
json.employee_no allowance.employee_no
json.employee_name allowance.employee_name
json.department_name allowance.department_name
json.position_name allowance.position_name
json.channel_id allowance.channel_id
json.remark allowance.remark
json.notes allowance.notes
json.month allowance.month
json.employee_id allowance.employee_id
json.add_garnishee format("%.2f", allowance.add_garnishee || 0)
json.subsidy format("%.2f", allowance.subsidy || 0)
json.category 'land_allowance'
json.id performance_salary.id
json.employee_no performance_salary.employee_no
json.employee_name performance_salary.employee_name
json.department_name performance_salary.department_name
json.position_name performance_salary.position_name
json.channel_id performance_salary.channel_id
json.base_salary format("%.2f" , performance_salary.base_salary || 0)
json.amount format("%.2f", performance_salary.amount || 0)
json.add_garnishee format("%.2f", performance_salary.add_garnishee || 0)
json.remark performance_salary.remark
json.notes performance_salary.notes
json.month performance_salary.month
json.employee_id performance_salary.employee_id
json.category 'performance_salary'
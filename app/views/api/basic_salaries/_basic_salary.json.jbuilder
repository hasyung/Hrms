json.id salary.id
json.employee_id salary.employee_id
json.employee_no salary.employee_no
json.employee_name salary.employee_name
json.department_name salary.department_name
json.position_name salary.position_name
json.channel_id salary.channel_id
json.position_salary format("%.2f", salary.position_salary || 0)
json.working_years_salary format("%.2f", salary.working_years_salary || 0)
json.add_garnishee format("%.2f", salary.add_garnishee || 0)
json.remark salary.remark
json.notes salary.notes
json.month salary.month

json.category 'basic_salary'
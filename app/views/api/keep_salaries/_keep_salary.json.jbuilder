json.id keep_salary.id
json.employee_id keep_salary.employee_id
json.employee_name keep_salary.employee_name
json.employee_no keep_salary.employee_no
json.channel_id keep_salary.channel_id
json.department_name keep_salary.department_name
json.position_name keep_salary.position_name
json.month keep_salary.month
json.remark keep_salary.remark
json.notes keep_salary.notes

json.position format("%.2f" , keep_salary.position || 0)
json.performance format("%.2f" , keep_salary.performance || 0)
json.working_years format("%.2f" , keep_salary.working_years || 0)
json.minimum_growth format("%.2f" , keep_salary.minimum_growth || 0)
json.land_allowance format("%.2f" , keep_salary.land_allowance || 0)
json.life_1 format("%.2f" , keep_salary.life_1 || 0)
json.life_2 format("%.2f" , keep_salary.life_2 || 0)
json.adjustment_09 format("%.2f" , keep_salary.adjustment_09 || 0)
json.bus_14 format("%.2f" , keep_salary.bus_14 || 0)
json.communication_14 format("%.2f" , keep_salary.communication_14 || 0)

json.add_garnishee format("%.2f" , keep_salary.add_garnishee || 0)

json.category 'keep_salary'

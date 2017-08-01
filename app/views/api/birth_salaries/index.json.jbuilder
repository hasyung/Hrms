json.birth_salaries @birth_salaries do |salary|
  json.id salary.id
  json.employee_id salary.employee_id
  json.employee_no salary.employee_no
  json.employee_name salary.employee_name
  json.department_name salary.department_name
  json.position_name salary.position_name
  json.channel_id salary.channel_id

  json.basic_salary format("%.2f", salary.basic_salary || 0)
  json.working_years_salary format("%.2f", salary.working_years_salary || 0)
  json.keep_salary format("%.2f", salary.keep_salary || 0)
  json.performance_salary format("%.2f", salary.performance_salary || 0)
  json.hours_fee format("%.2f", salary.hours_fee || 0)
  json.security_fee format("%.2f", salary.security_fee || 0)
  json.budget_reward format("%.2f", salary.budget_reward || 0)
  json.transport_fee format("%.2f", salary.transport_fee || 0)
  json.temp_allowance format("%.2f", salary.temp_allowance || 0)
  json.residue_money format("%.2f", salary.residue_money || 0)
  json.birth_residue_money format("%.2f", salary.birth_residue_money || 0)
  json.after_residue_money format("%.2f", salary.after_residue_money || 0)
  json.remark salary.remark
  json.bus_fee format("%.2f", salary.bus_fee || 0)
  json.notes salary.notes
  json.month salary.month

  json.category 'birth_salary'
end

json.partial! 'shared/page_basic'
json.salary_overview do
  json.id @salary_overview.id
  json.employee_no @salary_overview.employee_no
  json.employee_name @salary_overview.employee_name
  json.department_name @salary_overview.department_name
  json.position_name @salary_overview.position_name
  json.channel_id @salary_overview.channel_id
  json.basic format("%.2f" , @salary_overview.basic || 0)
  json.keep format("%.2f", salary_overview.keep || 0)
  json.performance format("%.2f", @salary_overview.performance || 0)
  json.hours_fee format("%.2f", @salary_overview.hours_fee || 0)
  json.security_fee format("%.2f", @salary_overview.security_fee || 0)
  json.subsidy format("%.2f", @salary_overview.subsidy || 0)
  json.land_subsidy format("%.2f" , @salary_overview.land_subsidy || 0)
  json.reward format("%.2f" , @salary_overview.reward || 0)
  json.transport_fee format("%.2f" , @salary_overview.transport_fee || 0)
  json.total format("%.2f" , @salary_overview.total || 0)
  json.bus_fee format("%.2f", @salary_overview.bus_fee || 0)
  json.official_car format("%.2f", @salary_overview.official_car || 0)
  json.remark @salary_overview.remark
  json.notes @salary_overview.notes
  json.month @salary_overview.month
  json.employee_id @salary_overview.employee_id
  json.category 'salary_overview'
end

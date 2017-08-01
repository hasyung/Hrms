json.temps @employees do |employee|
  json.id                      employee.id
  json.employee_no             employee.employee_no
  json.name                    employee.name
  json.channel_id              employee.channel_id
  json.duty_rank_id            employee.duty_rank_id
  json.join_scal_date          employee.join_scal_date
  json.month_distribute_base   employee.month_distribute_base.to_f
  json.pcategory               employee.pcategory

  json.department do
    json.id employee.department_id
    json.name employee.department.full_name
  end

  json.position do
    json.name EmployeePosition.full_position_name(employee.employee_positions)
  end
end

json.partial! 'shared/page_basic'

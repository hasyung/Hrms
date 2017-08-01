json.salary_change do
  employee = Employee.unscoped.find_by(id: @salary_change.employee_id)
  json.id @salary_change.id
  json.employee_id @salary_change.employee_id
  json.employee_name @salary_change.employee_name
  json.employee_no @salary_change.employee_no
  json.department_name @salary_change.department_name
  json.position_name @salary_change.position_name
  json.category @salary_change.category
  json.state @salary_change.state
  json.change_date @salary_change.change_date
  json.prev_channel_id @salary_change.prev_channel_id
  if(@salary_change.position_name_history)
    json.position_name_history @salary_change.position_name_history
  end
  if(@salary_change.reason)
    json.reason @salary_change.reason
  end
  json.location employee.try(:location)
  json.identity_no employee.try(:identity_no)
  json.labor_relation_name employee.try(:labor_relation).try(:display_name)

  if @salary_change.salary_setup_cache
    json.salary_setup_cache @salary_change.salary_setup_cache.data
    json.prev_category_id @salary_change.salary_setup_cache.prev_category_id
    json.prev_channel_id @salary_change.salary_setup_cache.prev_channel_id
    json.prev_department_name @salary_change.salary_setup_cache.prev_department_name
    json.prev_position_name @salary_change.salary_setup_cache.prev_position_name
    json.prev_location @salary_change.salary_setup_cache.prev_location
  else
    json.salary_setup_cache nil
    json.prev_category_id employee.category_id
    json.prev_channel_id @salary_change.prev_channel_id
    json.prev_department_name @salary_change.department_name
    json.prev_position_name @salary_change.position_name
    json.prev_location employee.try(:location)
  end

  json.salary_person_setup_id @salary_change.salary_person_setup_id
end
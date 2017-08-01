json.salary_changes @salary_changes do |salary|
  employee = Employee.unscoped.find_by(id: salary.employee_id)
  json.category_id         employee.category_id
  json.channel_id          employee.channel_id
  json.labor_relation_id   employee.labor_relation_id
  json.location            employee.try(:location)
  json.identity_no         employee.try(:identity_no)
  json.labor_relation_name employee.try(:labor_relation).try(:display_name)
  json.join_scal_date      employee.join_scal_date

  json.id              salary.id
  json.employee_id     salary.employee_id
  json.employee_name   salary.employee_name
  json.employee_no     salary.employee_no
  json.department_name salary.department_name
  json.position_name   salary.position_name
  json.category        salary.category
  json.state           salary.state
  json.change_date     salary.change_date
  json.prev_channel_id salary.prev_channel_id

  if(salary.position_name_history)
    json.position_name_history salary.position_name_history
  end

  if(salary.reason)
    json.reason salary.reason
  end

  if salary.salary_setup_cache
    json.salary_setup_cache salary.salary_setup_cache.data
    json.prev_category_id salary.salary_setup_cache.prev_category_id
    json.prev_channel_id salary.salary_setup_cache.prev_channel_id
    json.prev_department_name salary.salary_setup_cache.prev_department_name
    json.prev_position_name salary.salary_setup_cache.prev_position_name
    json.prev_location salary.salary_setup_cache.prev_location
  else
    json.salary_setup_cache nil
    json.prev_category_id employee.category_id
    json.prev_channel_id salary.prev_channel_id
    json.prev_department_name salary.department_name
    json.prev_position_name salary.position_name
    json.prev_location employee.try(:location)
  end

  json.salary_person_setup_id salary.salary_person_setup_id
end

json.partial! 'shared/page_basic'

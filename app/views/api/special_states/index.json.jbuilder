json.special_states @special_states do |item|
  employee = Employee.unscoped.find_by(id:item.employee_id)
  json.id                     item.id
  json.employee_id            employee.id
  json.sponsor                Employee.find_by(id: item.sponsor_id).try(:name)
  json.employee_no            employee.employee_no
  json.employee_name          employee.name
  json.position_name          EmployeePosition.full_position_name(employee.employee_positions)
  json.special_category       item.special_category
  json.special_time           item.created_at.strftime("%Y-%m-%d")
  json.special_location       item.special_location
  json.file_no                item.file_no
  json.limit_time             "#{item.special_date_from}至#{item.special_date_to.present? ? item.special_date_to : "无期限"}"
  json.special_date_from      item.special_date_from
  json.special_date_to        item.special_date_to
  json.stop_fly_reason        item.stop_fly_reason

  json.department do
    json.id     employee.department_id
    json.name   employee.department.full_name
  end
end

json.partial! 'shared/page_basic'

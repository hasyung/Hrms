json.id dinner_change.id
json.employee_id dinner_change.employee_id
json.employee_no dinner_change.employee_no
json.employee_name dinner_change.employee_name
json.change_category dinner_change.category
json.state dinner_change.state
json.change_date dinner_change.change_date
json.leave_type dinner_change.leave_type if dinner_change.leave_type
json.duration_date dinner_change.duration_date if dinner_change.start_date
json.point dinner_change.point if dinner_change.point

employee = Employee.unscoped.find_by(id: dinner_change.employee_id)
master_position = EmployeePosition.unscoped.where(employee_id: dinner_change.employee_id, category: "主职").order(:end_date).first.try(:position)
if employee
  json.department_name employee.department.full_name
  json.position_name master_position.try(:name)
  json.location employee.location
  json.category employee.category.try(:display_name)
end
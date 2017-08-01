json.education_experience_records @education_experience_records do |record|
  employee = record.employee || Employee.unscoped.find_by(id: record.employee_id)
  json.employee_id record.employee_id
  json.employee_name record.employee_name
  json.employee_no record.employee_no
  json.department_name record.department_name
  json.position_name EmployeePosition.full_position_name(employee.try(:employee_positions).to_a)
  json.identity_no employee.try(:identity_no)
  json.labor_relation employee.try(:labor_relation).try(:display_name)
  json.school record.school
  json.major record.major
  json.education_background record.education_background.try(:display_name)
  json.degree record.degree.try(:display_name)
  json.graduation_date record.graduation_date
  json.change_date record.change_date
end

json.partial! 'shared/page_basic'
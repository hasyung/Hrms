employee = Employee.unscoped.find_by(id: social.employee_id)
json.id social.id
json.employee_id social.employee_id
json.employee_name social.employee_name
json.employee_no social.employee_no
json.department_name social.department_name
json.category social.category
json.state social.state
json.change_date social.change_date
if(social.indentity_no_was)
  json.identity_no_was social.indentity_no_was
end
if(social.location_was)
  json.location_was social.location_was
end
if(social.salary_reason)
  json.salary_reason social.salary_reason
end
json.location employee.try(:location)
json.identity_no employee.try(:identity_no)
json.labor_relation_name employee.try(:labor_relation).try(:display_name)

if(social.social_person_setup_id)
  json.social_location employee.try(:social_person_setup).try(:social_location)
end

json.social_person_setup_id social.social_person_setup_id

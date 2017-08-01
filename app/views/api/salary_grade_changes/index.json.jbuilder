json.salary_grade_changes @salary_grade_changes do |grade_change|
  json.id grade_change.id
  json.employee_id grade_change.employee_id
  json.employee_no grade_change.employee_no
  json.employee_name grade_change.employee_name
  json.labor_relation_id grade_change.labor_relation_id
  json.channel_id grade_change.channel_id
  json.record_date grade_change.record_date
  json.change_module grade_change.change_module
  json.form_data    grade_change.form_data
  json.department do
    json.id grade_change.employee.department.id
    json.name grade_change.employee.department.full_name
  end
end

json.partial! 'shared/page_basic'

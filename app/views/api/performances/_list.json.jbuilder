json.performances @performances do |performance|
  json.id                performance.id
  json.employee_name     performance.employee_name
  json.employee_id       performance.employee_id
  json.employee_no       performance.employee_no
  json.department_name   performance.department_name
  json.position_name     performance.position_name
  json.channel           performance.channel
  json.assess_time       performance.format_assess_time
  json.assess_year       performance.assess_year
  json.result            performance.result
  json.sort_no           performance.sort_no
  json.employee_category performance.employee_category
  json.category          performance.category
  json.category_name     performance.category_name
  json.created_at        performance.created_at
  json.attachment_status performance.attachments.present?
  json.allege_status     performance.allege.present?
end

json.id allege.id
json.performance_id allege.performance_id
json.employee_id allege.performance.employee_id
json.employee_name allege.performance.employee_name
json.employee_no allege.performance.employee_no
json.department_name allege.performance.department_name
json.position_name allege.performance.position_name
json.channel allege.performance.channel
json.labor_relation allege.performance.employee.labor_relation.try(:display_name)
json.assess_time allege.performance.format_assess_time
json.result allege.performance.result
json.category_name allege.performance.category_name
json.performance_was allege.performance_was
json.reason allege.reason
json.outcome allege.outcome
json.created_at allege.created_at
json.is_managed (allege.outcome == "通过" or allege.outcome == "驳回")
json.sort_no allege.performance.sort_no

if attachments.present? && @current_employee.id != allege.performance.employee_id
  json.allege_attachments attachments do |attachment|
    json.id attachment.id
    json.name attachment.file_name
    json.type attachment.file_type
    json.size attachment.file_size
    json.default Setting.upload_url + attachment.file.url
  end
else
  json.allege_attachments []
end

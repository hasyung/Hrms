json.change_logs @change_logs do |log|
  json.id log.id
  json.title log.title
  json.oa_file_no  log.oa_file_no
  json.step_desc log.step_desc.split(";")
  json.dep_name log.dep_name
  json.created_at log.created_at
  json.creator Employee.unscoped.find_by(id: log.employee_id).try(:name)
end

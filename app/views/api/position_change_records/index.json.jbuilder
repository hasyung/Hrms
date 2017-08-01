json.position_change_records @position_change_records do |record|
  employee = record.employee

  json.id record.id
  json.employee_id record.employee_id
  json.employee_no employee.employee_no
  json.employee_name employee.name
  json.department_name employee.department.full_name
  json.position_name employee.master_position.name
  json.operator_name record.operator_name
  json.created_at record.created_at
  json.position_change_date record.position_change_date
  json.channel_id record.channel_id
  json.category_id record.category_id
  json.duty_rank_id record.duty_rank_id
  json.position_remark record.position_remark
  json.oa_file_no record.oa_file_no
  json.position_change_date record.position_change_date
  json.probation_duration record.probation_duration
  json.classification record.classification
  json.location record.location

  json.positions record.position_form do |form|
    json.category form["category"]
    json.position_name Position.find(form["position_id"]).name
    json.department_name Department.find(form["department_id"]).full_name
  end
end

json.position_records @records do |record|
  json.id                  record.id
  json.employee_id         record.employee_id
  json.employee_name       record.employee_name
  json.employee_no         record.employee_no
  json.gender_name         record.gender_name
  json.labor_relation_id   record.labor_relation_id
  json.change_date         record.change_date

  json.pre_department_name  record.pre_department_name
  json.pre_position_name    record.pre_position_name
  json.pre_category_name    record.pre_category_name
  json.pre_channel_name     record.pre_channel_name
  json.pre_location         record.pre_location
  json.pre_duty_rank_name   record.pre_duty_rank_name
  json.pre_classification   record.pre_classification

  json.department_name   record.department_name
  json.position_name     record.position_name
  json.category_name     record.category_name
  json.channel_name      record.channel_name
  json.location          record.location
  json.duty_rank_name    record.duty_rank_name
  json.classification    record.classification

  json.oa_file_no        record.oa_file_no
  json.note              record.note
end

json.partial! 'shared/page_basic'

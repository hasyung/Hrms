json.social_records @social_records do |record|
  json.id record.id
  json.employee_id record.employee_id
  json.employee_no record.employee_no
  json.employee_name record.employee_name
  json.department_name record.department_name
  json.social_location record.social_location
  json.social_account record.social_account
  json.pension_cardinality record.pension_cardinality
  json.other_cardinality record.other_cardinality
  json.personage_total format("%.2f", record.t_personage)
  json.company_total format("%.2f", record.t_company)
  json.total format("%.2f", record.t_personage + record.t_company)
  json.month record.compute_month
end

json.partial! 'shared/page_basic'
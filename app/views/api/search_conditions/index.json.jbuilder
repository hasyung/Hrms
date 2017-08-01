json.search_conditions @conditions do |condition|
  json.id condition.id
  json.employee_id condition.employee_id
  json.name condition.name
  json.code condition.code
  json.condition condition.condition
end

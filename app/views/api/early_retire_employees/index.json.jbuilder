json.early_retire_employees @early_retire_employees do |early_retire_employee|
  json.id early_retire_employee.id
  json.employee_id early_retire_employee.employee_id
  json.name early_retire_employee.name
  json.department early_retire_employee.department
  json.employee_no early_retire_employee.employee_no
  json.labor_relation early_retire_employee.labor_relation
  json.file_no early_retire_employee.file_no
  json.change_date early_retire_employee.change_date
  json.position early_retire_employee.position
  json.channel early_retire_employee.channel
  json.gender early_retire_employee.gender
  json.birthday early_retire_employee.birthday
  json.identity_no early_retire_employee.identity_no
  json.join_scal_date early_retire_employee.join_scal_date
  json.remark early_retire_employee.remark
end

json.meta do
  if @total_pages
    json.pages_count @total_pages
    json.page @page
    json.per_page @per_page
    json.count @count
  end
end

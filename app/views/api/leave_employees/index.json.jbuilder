json.leave_employees @leave_employees do |leave_employee|
  json.id leave_employee.id
  json.employee_id leave_employee.employee_id
  json.name leave_employee.name
  json.department leave_employee.department
  json.employee_no leave_employee.employee_no
  json.labor_relation leave_employee.labor_relation
  json.file_no leave_employee.file_no
  json.change_date leave_employee.change_date
  json.position leave_employee.position
  json.employment_status leave_employee.employment_status
  json.channel leave_employee.channel
  json.gender leave_employee.gender
  json.birthday leave_employee.birthday
  json.identity_no leave_employee.identity_no
  json.join_scal_date leave_employee.join_scal_date
  json.remark leave_employee.remark
end

json.meta do
  if @total_pages
    json.pages_count @total_pages
    json.page @page
    json.per_page @per_page
    json.count @count
  end
end

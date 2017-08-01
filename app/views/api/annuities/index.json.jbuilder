json.annuities @employees do |employee|
  json.id                    employee.id
  json.employee_id           employee.id
  json.employee_no           employee.employee_no
  json.name                  employee.name
  json.identity_no           employee.identity_no
  json.mobile                employee.contact.mobile
  json.annuity_cardinality   employee.annuity_cardinality.try(:to_f) || 0
  json.annuity_status        employee.annuity_status ? "在缴" : "退出"

  json.department do
    json.id     employee.department_id
    json.name   employee.department.full_name
  end
end

json.partial! 'shared/page_basic'

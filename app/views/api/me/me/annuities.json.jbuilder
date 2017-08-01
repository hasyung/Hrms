json.annuities @annuities do |annuity|
  json.id                    annuity.id
  json.employee_no           annuity.employee_no
  json.employee_name         annuity.employee_name
  json.department_name       annuity.department_name
  json.position_name         annuity.position_name
  json.cal_date              annuity.cal_date
  json.annuity_cardinality   annuity.annuity_cardinality
  json.personal_payment      annuity.personal_payment
  json.company_payment       annuity.company_payment
end

json.meta do
  json.annuity_status @annuity_status
  json.annuity_apply_status @annuity_apply_status
  json.can_join_annuity @can_join_annuity
end

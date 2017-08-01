json.annuities @annuities do |annuity|
  json.employee_id           annuity.employee_id
  json.cal_date              annuity.cal_date
  json.employee_no           annuity.employee_no
  json.employee_name         annuity.employee_name
  json.department_name       annuity.department_name
  json.position_name         annuity.position_name
  json.identity_no           annuity.identity_no
  json.mobile                annuity.mobile
  json.annuity_cardinality   annuity.annuity_cardinality
  json.company_payment       annuity.company_payment
  json.personal_payment      annuity.personal_payment
  json.note                  annuity.note
end

json.partial! 'shared/page_basic'

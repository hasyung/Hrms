json.annuity_applies @annuity_applies do |annuity_apply|
  json.id                annuity_apply.id
  json.employee_no       annuity_apply.employee_no
  json.employee_name     annuity_apply.employee_name
  json.department_name   annuity_apply.department_name
  json.apply_category    annuity_apply.apply_category
  json.status            annuity_apply.status ? "已处理" : "未处理"
  json.created_at        annuity_apply.created_at
  json.employee_id       annuity_apply.employee_id
end

json.partial! 'shared/page_basic'

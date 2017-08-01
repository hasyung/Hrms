json.notifications @notifications do |notification|
  json.id notification.id
  json.category I18n.t("flow.type.#{notification.category}")
  json.body notification.body
  json.confirmed notification.confirmed
  json.confirmed_at notification.confirmed_at
  json.employee_id notification.employee_id
  json.created_at notification.created_at
  json.updated_at notification.updated_at
end
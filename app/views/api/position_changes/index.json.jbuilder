json.audits @audits do |audit, position=Position.unscoped{audit.associated || audit.auditable}|
  json.id audit.id
  json.name position.blank? ? audit.audited_changes['name'] : position.try(:name)
  json.auditable_type I18n.t('enums.audit.auditable_types.' + audit.auditable_type.constantize.table_name.chop)

  json.department do
    json.id position.blank? ? audit.audited_changes['department_id'] : position.try(:department_id)
    json.name position.blank? ? Department.find(audit.audited_changes['department_id']).full_name : (position.try(:department).blank? ? nil : position.department.full_name)
  end

  user = Employee.unscoped.find_by(id: audit.user_id)
  if user
    json.user do
      json.id user.id
      json.employee_no user.employee_no
      json.name user.name
    end
  end

  json.action I18n.t('enums.audit.action.' + audit.action)
  json.created_at audit.created_at
  # json.audited_changes audit.change_data_foreign_key
  json.remark audit.remark
end

json.partial! 'shared/page_basic'

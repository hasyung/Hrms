json.audit do
  employee = Employee.unscoped.find_by(id: @audit.associated_id) || Employee.unscoped.find_by(id: @audit.auditable_id)
  master_position = EmployeePosition.unscoped.where(employee_id: employee.try(:id), category: "主职").order(:end_date).first.try(:position)
  json.id @audit.id
  json.employee_no employee.try(:employee_no)
  json.name employee.try(:name)
  json.auditable_type I18n.t('enums.audit.auditable_types.' + @audit.auditable_type.constantize.table_name.chop)

  json.department do
    json.id master_position.try(:department).try(:id)
    json.name master_position.try(:department).try(:full_name)
  end

  user = Employee.unscoped.find_by(id: @audit.user_id)
  if user
    json.user do
      json.id user.id
      json.employee_no user.employee_no
      json.name user.name
    end
  end

  json.action I18n.t('enums.audit.action.' + @audit.action)
  json.status_cd @audit.status_cd
  json.created_at @audit.created_at
  json.audited_changes @audit.change_data_foreign_key
  json.check_date @audit.check_date
  json.reason @audit.reason
end

json.auditable_types Audit::EMPLOYEE_TYPES.keys
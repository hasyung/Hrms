json.employee do
  json.partial! 'shared/employee_basic', employee: @employee, employee_positions: @emp_pos, master_position: @master_position, languages: @emp_languages
  json.technical_grade @employee.salary_person_setup.try(:technical_grade)
end

json.meta do
  if @audits.present?
    json.audited_changes @audits.map(&:audited_changes).inject(&:merge!)
  end
end

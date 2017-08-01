json.employee do
  json.partial! 'shared/employee_basic', employee: @employee, employee_positions: @emp_pos, master_position: @master_position, languages: @emp_languages
  
  json.permissions @employee.get_all_controller_actions.inject([]){|arr, p|arr << (p.controller + '_' + p.action)}

  json.vacations @employee.vacation_summary

  json.work_shifts @employee.work_shifts.where(end_time: nil).first.try(:work_shifts) || "行政班"
end

json.meta do
  if @audits.present?
    json.audited_changes @audits.map(&:audited_changes).inject(&:merge!)
  end
end

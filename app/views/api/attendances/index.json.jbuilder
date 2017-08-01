json.attendances @attendances  do |attendance|
	next if attendance.employee.nil?
  json.id attendance.id
  json.record_type attendance.record_type
  json.record_date attendance.record_date

  json.user do
    json.partial! 'shared/employee_basic', employee: attendance.employee, employee_positions: attendance.employee.employee_positions, master_position: attendance.employee.master_position, languages: attendance.employee.languages
  end
end

json.partial! 'shared/page_basic'

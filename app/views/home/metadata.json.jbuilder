json.user do
  json.partial! 'shared/employee_basic', employee: @employee, employee_positions: @employee_positions, languages: @emp_languages
end

json.permissions @employee.get_all_controller_actions.inject( [] ) { |arr, p| arr << (p.controller + '_' + p.action) }

json.resources @resources

json.type @type

json.messages @messages

json.vacation_summary @employee.vacation_summary

json.roles @roles

json.roles_menu_config @roles_menu_config

json.salary_setting @salary_setting

json.push_server PushServerSetting.to_h

json.route_info do
  json.default_route "/dashboard"
  json.single_point cookies['single_point'] || false
end

json.report_checker @report_checker

json.id                    employee.id
json.name                  employee.name
json.employee_no           employee.employee_no
json.identity_no           employee.identity_no
json.school                employee.school
json.graduate_date         employee.graduate_date
json.birth_place           employee.birth_place
json.native_place          employee.native_place
json.birthday              employee.birthday
json.start_work_date       employee.start_work_date
json.join_scal_date        employee.join_scal_date
json.start_internship_date employee.start_internship_date
json.scal_working_years    employee.scal_working_years
json.start_working_years   employee.start_working_years
json.join_party_date       employee.join_party_date

json.approve_leave_job_date employee.approve_leave_job_date
json.leave_job_reason       employee.leave_job_reason
json.is_delete              employee.is_delete

json.major           employee.major
json.technical_duty  employee.technical_duty
json.position_remark employee.position_remark

json.political_status_id     employee.political_status_id
json.nationality             employee.nationality
json.nation                  employee.nation
json.location                employee.location
json.category_id             employee.category_id || employee.master_position.category_id
json.channel_id              employee.channel_id || employee.master_position.channel_id
json.labor_relation_id       employee.labor_relation_id
json.duty_rank_id            employee.duty_rank_id
json.education_background_id employee.education_background_id
json.degree_id               employee.degree_id
json.gender_id               employee.gender_id
json.job_title_degree_id     employee.job_title_degree_id
json.job_title               employee.job_title
json.marital_status_id       employee.marital_status_id
json.pcategory               employee.pcategory
json.probation_months        employee.probation_months.to_i
#json.english_level_id       employee.english_level_id
json.classification          employee.classification
json.leave_days              employee.leave_days
json.star                    employee.star

json.favicon do
  if employee.favicon.present?
    json.default (Setting.upload_url + employee.favicon.url)
    json.small   (Setting.upload_url + employee.favicon.small.url)
    json.middle  (Setting.upload_url + employee.favicon.middle.url)
    json.big     (Setting.upload_url + employee.favicon.big.url)
  else
    json.small  (Setting.upload_url + default_favicon(employee, 'small'))
    json.middle (Setting.upload_url + default_favicon(employee, 'middle'))
    json.big    (Setting.upload_url + default_favicon(employee, 'big'))
  end
end

json.employment_status_id employee.employment_status_id
json.contact              employee.contact

json.position do
  json.name EmployeePosition.full_position_name(employee_positions)
end

json.department do
  json.id employee.department_id
  json.name employee.department.try(:full_name)
end

json.positions employee_positions do |employee_position|
  position = employee_position.position
  json.position do
    json.id   position.id
    json.name position.name
  end
  json.category employee_position.category
  json.department do
    json.id   position.department_id
    json.name position.department.full_name
  end
end

json.languages languages do |language|
  json.name  language.name
  json.grade language.grade
end

json.age                   employee.age
json.master_position_name  employee.master_position.try(:name)
json.master_position_years employee.master_position_years
json.last_contact_duration employee.last_contact_duration
json.year_performance      employee.year_performance
json.six_performances      employee.get_any_performances(6)
json.twelve_performances   employee.get_any_performances(12)
json.leave_date            employee.leave_date

json.annuity_cardinality         employee.annuity_cardinality
json.annuity_status              employee.annuity_status ? "在缴" : "退出"
json.change_contract_date        employee.change_contract_date
json.change_contract_system_date employee.change_contract_system_date
json.technical                   employee.technical

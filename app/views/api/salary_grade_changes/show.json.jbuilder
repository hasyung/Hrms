json.salary_grade_change do
  json.employee_id          @salary_grade_change.employee_id
  json.employee_no          @salary_grade_change.employee_no
  json.employee_name        @salary_grade_change.employee_name
  json.labor_relation_id    @salary_grade_change.labor_relation_id
  json.channel_id           @salary_grade_change.channel_id
  json.record_date          @salary_grade_change.record_date
  json.change_module        @salary_grade_change.change_module
  json.form_data            @salary_grade_change.form_data
  json.department_name      @salary_grade_change.department_name
  json.position_name        @salary_grade_change.position_name
  json.last_transfer_date   @salary_grade_change.last_transfer_date
  json.fly_total_time       @salary_grade_change.fly_total_time
  json.education_background @salary_grade_change.employee.education_background.try(:display_name)
  json.job_title_degree     @salary_grade_change.employee.job_title_degree.try(:display_name)
end

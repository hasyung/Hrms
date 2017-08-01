json.special_state do
  json.id                 @special_state.id
  json.employee_id        @special_state.employee_id
  json.sponsor            Employee.find_by(id: @special_state.sponsor_id).try(:name)
  json.department_id      @special_state.department_id
  json.special_category   @special_state.special_category
  json.special_location   @special_state.special_location
  json.special_time       @special_state.created_at.strftime('%Y-%m-%d')
  json.file_no            @special_state.file_no
  json.limit_time         "#{@special_state.special_date_from}至#{@special_state.special_date_to.present? ? @special_state.special_date_to : "无期限"}"
  json.special_date_from @special_state.special_date_from
  json.special_date_to  @special_state.special_date_to
  json.stop_fly_reason @special_state.stop_fly_reason
end

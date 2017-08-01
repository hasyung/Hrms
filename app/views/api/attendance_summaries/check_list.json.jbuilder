json.partial! '/api/attendance_summaries/list', attendance_summaries: @attendance_summaries

json.meta do
  if @total_pages
    json.pages_count @total_pages
    json.page @page
    json.per_page @per_page
    json.count @count
  end

  json.attendance_summary_status @attendance_summary_status do |attendance_summary_status|
    next if attendance_summary_status.department.blank? && attendance_summary_status.attendance_summaries.blank?
    json.id attendance_summary_status.id
    json.department_hr_checked attendance_summary_status.department_hr_checked
    json.department_leader_checked attendance_summary_status.department_leader_checked
    json.hr_department_leader_checked attendance_summary_status.hr_department_leader_checked
    json.hr_labor_relation_member_checked attendance_summary_status.hr_labor_relation_member_checked
    json.department_id attendance_summary_status.department_id
    json.department_name !attendance_summary_status.department_hr_checked && attendance_summary_status.department ? attendance_summary_status.department.try(:name) : attendance_summary_status.department_name

    json.hr_name attendance_summary_status.hr_name
    json.hr_confirmed_at attendance_summary_status.hr_confirmed_at.try(:strftime, "%Y-%m-%d %H:%M:%S")
    json.department_leader_name attendance_summary_status.department_leader_name
    json.department_leader_opinion attendance_summary_status.department_leader_opinion
    json.department_leader_confirmed_at attendance_summary_status.department_leader_confirmed_at.try(:strftime, "%Y-%m-%d %H:%M:%S")
    json.hr_leader_name attendance_summary_status.hr_leader_name
    json.hr_department_leader_opinion attendance_summary_status.hr_department_leader_opinion
    json.hr_leader_confirmed_at attendance_summary_status.hr_leader_confirmed_at.try(:strftime, "%Y-%m-%d %H:%M:%S")
    json.hr_labor_relation_member_name attendance_summary_status.hr_labor_relation_member_name
    json.hr_labor_relation_member_opinion attendance_summary_status.hr_labor_relation_member_opinion
    json.hr_labor_relation_member_confirmed_at attendance_summary_status.hr_labor_relation_member_confirmed_at.try(:strftime, "%Y-%m-%d %H:%M:%S")
  end

  json.status @status
  json.department_id @current_attendance_summary_status.try(:department_id)
end

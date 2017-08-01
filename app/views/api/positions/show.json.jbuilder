json.position do
  json.id @position.id
  json.name @position.name
  json.budgeted_staffing @position.budgeted_staffing
  json.oa_file_no @position.oa_file_no
  json.staffing @position.staffing
  json.post_type @position.post_type
  json.staffing_remark @position.staffing_remark

  json.department do
    json.id @position.department_id
    json.name @position.department.name
  end

  json.channel_id @position.channel_id
  json.schedule_id @position.schedule_id
  json.category_id @position.category_id
  json.position_nature_id @position.position_nature_id
  json.created_at @position.created_at
end

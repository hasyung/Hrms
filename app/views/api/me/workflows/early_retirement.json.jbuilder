json.workflows @workflows do |workflow|
  json.receptor do 
    json.id @receptor.id
    json.name @receptor.name
    json.employee_no @receptor.employee_no
    json.position_name @receptor.master_position.name
    json.department_name @receptor.department.full_name
    json.gender @receptor.gender.try(:display_name)
    json.gender_id @receptor.gender_id
    json.birthday @receptor.birthday
    json.channel @receptor.channel.try(:display_name)
  end

  json.id workflow.id
  json.workflow_state workflow.t_current_state
  json.created_at workflow.created_at
end

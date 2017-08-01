json.workflows @workflows do |workflow|
  position = Position.find_by(id: workflow.to_position_id)

  json.id workflow.id
  json.receptor do 
    json.id @receptor.id
    json.name @receptor.name
    json.employee_no @receptor.employee_no
    json.position_name @receptor.master_position.name
    json.department_name @receptor.department.full_name
  end

  json.workflow_state workflow.t_current_state
  json.created_at workflow.created_at

  if position
    json.to_department_name position.department.name
    json.to_position_name position.name
  else
    json.to_department_name "<目标岗位不存在>"
    json.to_position_name "<目标岗位不存在>"
  end
end
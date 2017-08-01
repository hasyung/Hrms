json.workflows @workflows do |workflow|
  json.receptor do 
    json.id @receptor.id
    json.name @receptor.name
    json.employee_no @receptor.employee_no
    json.position_name @receptor.master_position.name
    json.department_name @receptor.department.full_name
    json.channel @receptor.channel.try(:display_name)
    json.labor_relation @receptor.labor_relation.try(:display_name)
  end

  json.id workflow.id
  json.workflow_state workflow.t_current_state
  json.created_at workflow.created_at
  json.leave_job_flow_state workflow.leave_job_flow_state
end
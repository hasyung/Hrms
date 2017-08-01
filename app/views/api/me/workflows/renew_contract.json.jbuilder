json.workflows @workflows do |workflow|
  json.receptor do 
    json.id @receptor.id
    json.name @receptor.name
    json.employee_no @receptor.employee_no
    json.position_name @receptor.master_position.name
    json.department_name @receptor.department.full_name
  end

  json.id workflow.id
  json.workflow_state workflow.t_current_state
  json.start_date workflow.start_date
  json.end_date workflow.end_date
  json.sign_state "续签"
end
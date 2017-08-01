json.workflows @workflows do |workflow|
  sponsor = Employee.unscoped.find(workflow.sponsor_id)
  receptor = Employee.unscoped.find(workflow.receptor_id)
  receptor_master_position = EmployeePosition.unscoped.where(employee_id: workflow.receptor_id, category: "主职").order(:end_date).first.try(:position)

  json.receptor do 
    json.id receptor.id
    json.name receptor.name
    json.employee_no receptor.employee_no
    json.position_name receptor_master_position.try(:name)
    json.department_name receptor_master_position.try(:department).try(:full_name)
    json.gender_id receptor.gender_id
    json.channel_id receptor.channel_id
    json.labor_relation_id receptor.labor_relation_id
  end

  json.receptor_id receptor.id 
  json.sponsor_id sponsor.id 

  json.id workflow.id
  json.name workflow.name
  json.type workflow.type
  json.workflow_state workflow.t_current_state
  json.created_at workflow.created_at
  if workflow.flow_end?
    json.updated_at workflow.updated_at
  end
end
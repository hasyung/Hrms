json.workflow do
  json.id @workflow.id
  json.name @workflow.name
  json.workflow_state @workflow.t_current_state
  json.created_at @workflow.created_at
  json.type @workflow.type
  json.updated_at @workflow.updated_at if @workflow.flow_end?

  sponsor = Employee.unscoped.find(@workflow.sponsor_id)
  receptor = Employee.unscoped.find(@workflow.receptor_id)
  sponsor_master_position = EmployeePosition.unscoped.where(employee_id: @workflow.sponsor_id, category: "主职").order(:end_date).first.try(:position)
  receptor_master_position = EmployeePosition.unscoped.where(employee_id: @workflow.receptor_id, category: "主职").order(:end_date).first.try(:position)
  json.sponsor do 
    json.id sponsor.id
    json.employee_no sponsor.employee_no
    json.name sponsor.name
    json.position_name sponsor_master_position.try(:name)
    json.department_name sponsor_master_position.try(:department).try(:full_name)
  end

  json.receptor do 
    json.id receptor.id
    json.employee_no receptor.employee_no
    json.name receptor.name
    json.position_name receptor_master_position.try(:name)
    json.department_name receptor_master_position.try(:department).try(:full_name)
  end

  json.receptor_id receptor.id 
  json.sponsor_id sponsor.id 

  json.form_data @workflow.serialized_form_data

  json.relation_data @workflow.relation_data

  json.flow_nodes @workflow.flow_nodes do |node|
    json.id node.id
    json.reviewer_id node.reviewer_id
    json.reviewer_name node.reviewer_name
    json.reviewer_position node.reviewer_position
    json.reviewer_department node.reviewer_department
    json.body node.body
    json.created_at node.created_at
  end

  json.attachments @workflow.flow_attachments do |attachment|
    json.id attachment.id
    json.name attachment.file_name
    json.type attachment.file_type
    json.size attachment.file_size
    json.default Setting.upload_url + attachment.file.url

    if attachment.file_type.include?("image/")
      json.thumb Setting.upload_url + attachment.file.url
    end
  end
end


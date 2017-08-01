json.workflows @workflows do |workflow|
  json.id workflow.id

  receptor = workflow.receptor
  json.receptor do 
    json.id receptor.id
    json.name receptor.name
    json.favicon get_favicon(receptor, 'middle')
  end

  json.created_at workflow.created_at
  json.updated_at workflow.updated_at
  json.type workflow.type
  json.name workflow.name
  json.desc workflow.todo_message
  json.viewer_favicons get_favicons(workflow.viewer_ids, 'small')
end
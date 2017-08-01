json.salary_position_relation do
  json.id @salary_position_relation.id
  json.salary_id @salary_position_relation.salary_id
  json.positions @salary_position_relation.position_ids do |position_id|
    position = Position.find position_id
    json.id   position.id
    json.name position.name
    json.department do
      json.name position.department.full_name
    end
  end
end
json.salary_position_relations @salary_position_relations do |salary_position_relation|
  json.id salary_position_relation.id
  json.salary_id salary_position_relation.salary_id
  json.salary_category salary_position_relation.salary.category
  json.positions salary_position_relation.position_ids do |position_id|
    position = @positions_hash[position_id]
    json.id   position.id
    json.name position.name
    json.department do
      json.name position.department.full_name
    end
  end
end
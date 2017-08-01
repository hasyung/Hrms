json.position_cold_subsidy @positions do |position|
  json.id position.id
  json.full_position_name position.name + "（" + position.department.full_name + "）"
  json.cold_subsidy_type position.cold_subsidy_type
end

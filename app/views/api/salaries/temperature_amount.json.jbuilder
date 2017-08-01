json.temperature_amounts @positions do |position|
  json.id position.id
  json.full_position_name position.name + "（" + position.department.full_name + "）"
  json.temperature_amount position.temperature_amount
end
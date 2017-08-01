json.temperature_amount do
  json.id @position.id
  json.full_position_name @position.name + "（" + @position.department.full_name + "）"
  json.temperature_amount @position.temperature_amount
end
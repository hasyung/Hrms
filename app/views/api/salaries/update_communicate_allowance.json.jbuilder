json.communicate_allowance do
  json.id @position.id
  json.full_position_name @position.name + "（" + @position.department.full_name + "）"
  json.communicate_allowance @position.communicate_allowance
end
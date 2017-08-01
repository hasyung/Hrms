json.communicate_allowance do
  json.id                    @record.id
  json.name                  @record.display_name
  json.communicate_allowance @record.communicate_allowance.to_i || 0
end

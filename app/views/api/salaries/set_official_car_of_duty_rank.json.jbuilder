json.official_car_allowance do
  json.id                     @record.id
  json.name                   @record.display_name
  json.official_car_allowance @record.official_car_allowance.to_i || 0
end

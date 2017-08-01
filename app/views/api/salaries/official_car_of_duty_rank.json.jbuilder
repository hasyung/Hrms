json.duty_ranks @records do |item|
  json.id                     item.id
  json.display_name           item.display_name
  json.communicate_allowance  item.communicate_allowance.to_i || 0
  json.official_car_allowance item.official_car_allowance.to_i || 0
end

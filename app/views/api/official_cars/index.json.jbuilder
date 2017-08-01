json.official_cars @official_cars do |official_car|
  json.id official_car.id
  json.employee_no official_car.employee_no
  json.employee_name official_car.employee_name
  json.department_name official_car.department_name
  json.position_name official_car.position_name
  json.fee format("%.2f" , official_car.fee || 0)
  json.add_garnishee format("%.2f" , official_car.add_garnishee || 0)
  json.remark official_car.remark
  json.month official_car.month
  json.employee_id official_car.employee_id
end

json.partial! 'shared/page_basic'
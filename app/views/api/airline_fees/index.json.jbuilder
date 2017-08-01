json.airline_fees @airline_fees do |item|
  json.id               item.id
  json.employee_id      item.employee_id
  json.employee_no      item.employee_no
  json.employee_name    item.employee_name
  json.department_name  item.department_name
  json.position_name    item.position_name
  json.month            item.month
  json.airline_fee      format("%.2f",item.airline_fee      || 0)
  json.airline_fee_cash format("%.2f",item.airline_fee_cash || 0)
  json.airline_fee_card format("%.2f",item.airline_fee_card || 0)
  json.oversea_food_fee format("%.2f",item.oversea_food_fee || 0)
  json.add_garnishee    format("%.2f",item.add_garnishee    || 0)
  json.remark           item.remark
  json.note             item.note
  json.total_fee        item.total_fee
  json.category         'oversea_food_fee'
end

json.partial! 'shared/page_basic'

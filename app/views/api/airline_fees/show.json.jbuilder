json.airline_fee do
  json.id               @airline_fee.id
  json.employee_id      @airline_fee.employee_id
  json.employee_no      @airline_fee.employee_no
  json.employee_name    @airline_fee.employee_name
  json.department_name  @airline_fee.department_name
  json.position_name    @airline_fee.position_name
  json.month            @airline_fee.month
  json.airline_fee      format("%.2f",@airline_fee.airline_fee      || 0)
  json.oversea_food_fee format("%.2f",@airline_fee.oversea_food_fee || 0)
  json.add_garnishee    format("%.2f",@airline_fee.add_garnishee    || 0)
  json.remark           @airline_fee.remark
  json.note             @airline_fee.note
  json.total_fee        @airline_fee.total_fee
end

json.rewards @rewards do |reward|
  json.id                       reward.id
  json.department_id            reward.department_id
  json.department_name          reward.department.name
  json.month                    reward.month
  json.flight_bonus             reward.flight_bonus.to_f
  json.service_bonus            reward.service_bonus.to_f
  json.airline_security_bonus   reward.airline_security_bonus.to_f
  json.composite_bonus          reward.composite_bonus.to_f
  json.insurance_proxy          reward.insurance_proxy.to_f
  json.cabin_grow_up            reward.cabin_grow_up.to_f
  json.full_sale_promotion      reward.full_sale_promotion.to_f
  json.article_fee              reward.article_fee.to_f
  json.all_right_fly            reward.all_right_fly.to_f
  json.year_composite_bonus     reward.year_composite_bonus.to_f
  json.move_perfect             reward.move_perfect.to_f
  json.security_special         reward.security_special.to_f
  json.dep_security_undertake   reward.dep_security_undertake.to_f
  json.fly_star                 reward.fly_star.to_f
  json.year_all_right_fly       reward.year_all_right_fly.to_f
  json.network_connect          reward.network_connect.to_f
  json.passenger_quarter_fee    reward.passenger_quarter_fee.to_f
  json.freight_quality_fee      reward.freight_quality_fee.to_f
  json.earnings_fee             reward.earnings_fee.to_f
  json.brand_quality_fee        reward.brand_quality_fee.to_f
end

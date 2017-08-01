json.dinner_fees @dinner_fees do |dinner_fee|
  json.partial! 'api/dinner_fees/dinner_fee', dinner_fee: dinner_fee
end

json.partial! 'shared/page_basic'
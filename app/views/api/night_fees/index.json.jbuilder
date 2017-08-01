json.night_fees @night_fees do |night_fee|
  json.partial! 'api/night_fees/night_fee', night_fee: night_fee
end

json.partial! 'shared/page_basic'

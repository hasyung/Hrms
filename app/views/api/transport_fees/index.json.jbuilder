json.transport_fees @transport_fees do |transport_fee|
  json.partial! 'api/transport_fees/transport_fee', transport_fee: transport_fee
end

json.partial! 'shared/page_basic'
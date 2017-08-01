json.land_allowances @land_allowances do |allowance|
  json.partial! 'api/land_allowances/land_allowance', allowance: allowance
end

json.partial! 'shared/page_basic'

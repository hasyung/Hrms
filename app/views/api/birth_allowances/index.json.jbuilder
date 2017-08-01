json.birth_allowances @birth_allowances do |birth_allowance|
  json.partial! 'api/birth_allowances/birth_allowance', birth_allowance: birth_allowance
end

json.partial! 'shared/page_basic'
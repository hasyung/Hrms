json.allowances @allowances do |salary|
  json.partial! 'api/allowances/allowance', salary: salary
end

json.partial! 'shared/page_basic'

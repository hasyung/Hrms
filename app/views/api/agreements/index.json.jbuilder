json.agreements @agreements do |agreement|
  json.partial! 'api/agreements/agreement', agreement: agreement
end

json.partial! 'shared/page_basic'

json.dinner_settles @dinner_settles do |dinner_settle|
  json.partial! 'api/dinner_settles/dinner_settle', dinner_settle: dinner_settle
end

json.partial! 'shared/page_basic'
json.dinner_changes @dinner_changes do |dinner_change|
  json.partial! 'api/dinner_changes/dinner_change', dinner_change: dinner_change
end

json.areas @areas

json.partial! 'shared/page_basic'
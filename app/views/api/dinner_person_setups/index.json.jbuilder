json.dinner_person_setups @dinner_person_setups do |dinner_person_setup|
  json.partial! 'api/dinner_person_setups/dinner_person_setup', dinner_person_setup: dinner_person_setup
end

json.areas @areas

json.partial! 'shared/page_basic'
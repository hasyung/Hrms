json.dinner_change do
  json.partial! 'api/dinner_changes/dinner_change', dinner_change: @dinner_change

  json.is_suspend @is_suspend

  json.dinner_person_setups @dinner_person_setups do |dinner_person_setup|
    json.partial! 'api/dinner_person_setups/dinner_person_setup', dinner_person_setup: dinner_person_setup
  end
end
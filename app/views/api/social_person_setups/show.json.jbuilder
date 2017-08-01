json.social_person_setup do
  json.partial! 'api/social_person_setups/setup', social: @social_person_setup

  json.identity_no @social_person_setup.employee.identity_no
  json.labor_relation_id @social_person_setup.employee.labor_relation_id
  json.location @social_person_setup.employee.location
  json.channel @social_person_setup.employee.channel.try(:display_name)
end
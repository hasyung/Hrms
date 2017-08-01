json.social_person_setups @social_person_setups do |social|
  json.partial! 'api/social_person_setups/setup', social: social
end

json.partial! 'shared/page_basic'
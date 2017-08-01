json.social_change_infos @social_change_infos do |social|
  json.partial! 'api/social_change_infos/info', social: social
end

json.partial! 'shared/page_basic'
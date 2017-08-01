class QuerySetting < Settingslogic
  source "#{Rails.root}/config/query.yml"
  namespace Rails.env
  load! if Rails.env.development?
end
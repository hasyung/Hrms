class PushServerSetting < Settingslogic
  source "#{Rails.root}/config/push_server.yml"
  namespace Rails.env
  load! if Rails.env.development?
end

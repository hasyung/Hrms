class FlowSetting < Settingslogic
  source "#{Rails.root}/config/flow.yml"
  namespace Rails.env
  load! if Rails.env.development?
end
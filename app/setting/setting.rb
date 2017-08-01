class Setting < Settingslogic
  source "#{Rails.root}/config/setting.yml"
  namespace Rails.env

  if File.exist?("#{Rails.root}/config/config.yml")
    instance.deep_merge!(Setting.new("#{Rails.root}/config/config.yml"))
  end

  load! if Rails.env.development?
end

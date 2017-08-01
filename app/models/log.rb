class Log < ActiveRecord::Base
  establish_connection "log_db_#{Rails.env}".to_sym
end

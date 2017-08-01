class ExternalApplication < ActiveRecord::Base
  serialize :client_ips, Array

  validates_presence_of :api_key
end

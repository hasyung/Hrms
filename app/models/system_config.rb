# == Schema Information
#
# Table name: system_configs
#
#  id         :integer          not null, primary key
#  key        :string(255)
#  value      :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class SystemConfig < ActiveRecord::Base
  validates_presence_of :key, :value

  def self.method_missing(method_name, *args, &block)
    item = self.where(key: method_name).first
    return item if item
    super
  end
end

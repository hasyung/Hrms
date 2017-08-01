# == Schema Information
#
# Table name: permissions
#
#  id            :integer          not null, primary key
#  category      :string(255)
#  controller    :string(255)
#  action        :string(255)
#  rw_type       :string(255)      default("read")
#  bit_value     :string(255)      default("0")
#  channel       :string(255)      default("none")
#  channel_value :string(255)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class Permission < ActiveRecord::Base
  validates_presence_of :category, :controller, :action, :channel
  validates_uniqueness_of :bit_value
  validates_uniqueness_of :controller, scope: [:controller, :action]

  before_create do |permission|
    bits_counter = SystemConfig.bits_counter
    permission.bit_value = (0b1 << bits_counter.value.to_i)
    bits_counter.update(value: (bits_counter.value.to_i + 1).to_s)
  end

  def grant_permission(employee)
    bit_value = employee.bit_value.to_i
    employee.bit_value = (bit_value | self.bit_value.to_i).to_s
    employee.save_without_auditing
  end

  def self.grant_bits(employee, bit_vlaue)
    employee.bit_value = (bit_value.to_i | self.bit_value.to_i).to_s
    employee.save_without_auditing
  end

  def operation_format
    I18n.t("log.#{self.controller}.#{self.action}")
  end

  def channel_password?
    self.channel == "password"
  end

  def channel_method?
    self.channel == "method"
  end

  def check_password?(password)
    self.channel_value == password
  end
end

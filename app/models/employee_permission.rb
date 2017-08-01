# == Schema Information
#
# Table name: employee_permissions
#
#  id          :integer          not null, primary key
#  bit_value   :string(255)      default("0")
#  expire_time :time
#  employee_id :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_employee_permissions_on_bit_value    (bit_value)
#  index_employee_permissions_on_expire_time  (expire_time)
#

class EmployeePermission < ActiveRecord::Base
  validates_presence_of :bit_value, :expire_time

  belongs_to :employee

  default_scope -> {where("expire_time < ?", Time.now)}

  def self.grant_bits(employee, bit_value, expire_time)
    create(employee_id: employee.id, bit_value: bit_value.to_s, expire_time: expire_time)
  end

  def self.cleanup
    self.where("expire_time < ?", Time.now).destroy_all
  end
end

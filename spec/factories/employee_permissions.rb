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

FactoryGirl.define do
  factory :employee_permission do
  end
end

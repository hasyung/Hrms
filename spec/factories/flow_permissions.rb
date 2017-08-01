# == Schema Information
#
# Table name: flow_permissions
#
#  id             :integer          not null, primary key
#  category       :string(255)
#  workflow       :string(255)
#  node           :string(255)
#  flow_bit_value :string(255)      default("0")
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

FactoryGirl.define do
  factory :flow_permission, :class => 'Flow::Permission' do
  end
end

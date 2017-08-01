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

FactoryGirl.define do
  factory :permission do
  end
end

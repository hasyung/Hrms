# == Schema Information
#
# Table name: specifications
#
#  id                   :integer          not null, primary key
#  duty                 :text(65535)
#  personnel_permission :text(65535)
#  financial_permission :text(65535)
#  business_permission  :text(65535)
#  superior             :text(65535)
#  underling            :text(65535)
#  internal_relation    :text(65535)
#  external_relation    :text(65535)
#  qualification        :text(65535)
#  position_id          :integer
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
# Indexes
#
#  index_specifications_on_position_id  (position_id)
#

FactoryGirl.define do
  factory :specification do
    duty 'xxx'
    personnel_permission 'xxx'
    financial_permission 'xxx'
    business_permission 'xxx'
    superior 'xxx'
    underling 'xxx'
    internal_relation 'xxx'
    external_relation 'xxx'
    qualification 'xxx'
  end
end

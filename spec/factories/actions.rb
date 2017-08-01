# == Schema Information
#
# Table name: actions
#
#  id          :integer          not null, primary key
#  model       :string(255)
#  category    :string(255)
#  description :string(255)
#  data        :text(65535)
#  employee_id :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_actions_on_category  (category)
#  index_actions_on_model     (model)
#

FactoryGirl.define do
  factory :action do
  end
end

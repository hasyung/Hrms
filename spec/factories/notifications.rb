# == Schema Information
#
# Table name: notifications
#
#  id           :integer          not null, primary key
#  category     :string(255)
#  body         :string(255)
#  confirmed    :boolean          default("0")
#  confirmed_at :time
#  employee_id  :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_notifications_on_category      (category)
#  index_notifications_on_confirmed     (confirmed)
#  index_notifications_on_confirmed_at  (confirmed_at)
#  index_notifications_on_employee_id   (employee_id)
#

FactoryGirl.define do
  factory :notification do
  end
end

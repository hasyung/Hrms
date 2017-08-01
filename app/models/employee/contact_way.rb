# == Schema Information
#
# Table name: employee_contact_ways
#
#  id              :integer          not null, primary key
#  telephone       :string(255)
#  mobile          :string(255)
#  address         :string(255)
#  mailing_address :string(255)
#  email           :string(255)
#  postcode        :string(255)
#  employee_id     :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

# 联系方式
class Employee::ContactWay < ActiveRecord::Base
  belongs_to :employee, class_name: 'Employee', inverse_of: :contact

  audited associated_with: :employee
end

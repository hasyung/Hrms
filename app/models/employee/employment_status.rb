# == Schema Information
#
# Table name: employee_employment_statuses
#
#  id           :integer          not null, primary key
#  name         :string(255)
#  display_name :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

#用工关系状态
class Employee::EmploymentStatus < ActiveRecord::Base
  has_many  :employees
end

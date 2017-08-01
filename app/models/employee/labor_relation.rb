# == Schema Information
#
# Table name: employee_labor_relations
#
#  id           :integer          not null, primary key
#  name         :string(255)
#  display_name :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class Employee::LaborRelation < ActiveRecord::Base
  include Pinyinable

  has_many :employees
end

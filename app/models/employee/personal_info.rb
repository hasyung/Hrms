# == Schema Information
#
# Table name: employee_personal_infos
#
#  id          :integer          not null, primary key
#  desc1       :string(255)
#  desc2       :string(255)
#  desc3       :string(255)
#  desc4       :string(255)
#  desc5       :string(255)
#  desc6       :string(255)
#  desc7       :string(255)
#  desc8       :string(255)
#  desc9       :string(255)
#  desc10      :string(255)
#  desc11      :string(255)
#  desc12      :string(255)
#  desc13      :string(255)
#  employee_id :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

# 联系方式
class Employee::PersonalInfo < ActiveRecord::Base
  belongs_to :employee, class_name: 'Employee', inverse_of: :personal_info

  audited associated_with: :employee
end

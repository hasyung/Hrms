# == Schema Information
#
# Table name: employee_work_experiences
#
#  id          :integer          not null, primary key
#  company     :string(255)
#  department  :string(255)
#  position    :string(255)
#  job_desc    :string(255)
#  job_title   :string(255)
#  start_date  :string(255)
#  end_date    :string(255)
#  witness     :string(255)
#  category    :string(255)      default("before")
#  employee_id :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

# 工作经历
class Employee::WorkExperience < ActiveRecord::Base
  belongs_to :employee, class_name: 'Employee', inverse_of: :work_experiences

  before_save :update_date_columns

  audited associated_with: :employee

  default_scope { order("start_date") }
  before_create :set_category

  private

  def set_category
    self.employee_category = self.employee.category.display_name
  end 

  def update_date_columns
    self.start_date = self.start_date.gsub('.', '-').at(0..9) if self.start_date
    self.end_date = self.end_date.gsub('.', '-').at(0..9) if self.end_date
  end
end

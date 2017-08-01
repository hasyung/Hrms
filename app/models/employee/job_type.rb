# == Schema Information
#
# Table name: employee_job_types
#
#  id           :integer          not null, primary key
#  name         :string(255)
#  display_name :string(255)
#

#职称类别
class Employee::JobType < ActiveRecord::Base
  has_many :job_title_degrees, class_name: 'Employee::JobTitleDegree'
end

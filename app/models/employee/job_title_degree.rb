# == Schema Information
#
# Table name: employee_job_title_degrees
#
#  id           :integer          not null, primary key
#  job_type_id  :integer
#  name         :string(255)
#  display_name :string(255)
#

#职称级别
class Employee::JobTitleDegree < ActiveRecord::Base
  has_many  :employees
  belongs_to :job_type, class_name: 'Employee::JobType'

  default_scope {order(level: 'desc')}
end

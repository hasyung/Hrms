class DepartmentSalary < ActiveRecord::Base
  belongs_to :department

  validates :month, uniqueness: { scope: [:month, :department_id] }
end

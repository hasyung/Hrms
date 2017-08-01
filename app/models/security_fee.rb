class SecurityFee < ActiveRecord::Base
	belongs_to :employee

	before_save :update_info, if: -> (info) { info.employee_id_changed? }

  validates :month, uniqueness: { scope: [:month, :employee_id] }

  private
  def update_info
    self.employee_no     = self.employee.employee_no
    self.employee_name   = self.employee.name
    self.department_name = self.employee.department.full_name
    self.position_name   = self.employee.master_position.name
  end
end

class TechnicalRecord < ActiveRecord::Base
	belongs_to :employee

	default_scope -> {order('change_date DESC')}

	after_save :update_employee_technical

	private
	def update_employee_technical
		self.employee.update(technical: self.employee.technical_records.first.technical)
	end
end

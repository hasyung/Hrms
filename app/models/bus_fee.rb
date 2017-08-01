class BusFee < ActiveRecord::Base
	belongs_to :employee

	before_save :update_info, if: -> (info) { info.employee_id_changed? }

	COLUMNS = %w(employee_id month employee_name employee_no department_name
    position_name fee total add_garnishee remark)

	def self.compute(month)
    BusFee.transaction do
      values, calc_values = [], []
      salaries_hash = BusFee.where(month: month).index_by(&:employee_id)

      Employee.includes(:department, :master_positions).where("employees.bus_fee > 0").each do |employee|
      	fee = employee.bus_fee
      	prev_month = Date.parse(month + "-01").prev_month.strftime("%Y-%m")
      	fee = 0 if employee.full_month_vacation?(prev_month)

      	values << [employee.id, month, employee.name, employee.employee_no, employee.department.full_name, 
      		employee.master_positions.first.try(:name), fee, fee, salaries_hash[employee.id].try(:add_garnishee), 
          salaries_hash[employee.id].try(:remark)
        ]
      end
      BusFee.where(month: month).delete_all
      BusFee.import(COLUMNS, values, validate: false)
    end
  end

	private
  def update_info
    self.employee_no     = self.employee.employee_no
    self.employee_name   = self.employee.name
    self.department_name = self.employee.department.full_name
    self.position_name   = self.employee.master_position.name
  end
end

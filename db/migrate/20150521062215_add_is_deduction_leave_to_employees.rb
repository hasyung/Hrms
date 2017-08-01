class AddIsDeductionLeaveToEmployees < ActiveRecord::Migration
  def change
    add_column :employees, :is_deduction_leave, :boolean, default: false
  end
end

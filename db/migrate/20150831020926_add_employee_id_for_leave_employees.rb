class AddEmployeeIdForLeaveEmployees < ActiveRecord::Migration
  def change
    add_column :leave_employees, :employee_id, :integer
  end
end

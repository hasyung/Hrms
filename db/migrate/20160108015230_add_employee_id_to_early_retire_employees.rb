class AddEmployeeIdToEarlyRetireEmployees < ActiveRecord::Migration
  def change
    add_column :early_retire_employees, :employee_id, :integer, default: 0, index: true
  end
end

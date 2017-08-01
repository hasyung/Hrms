class AddEmployeeIdForDepartmentChangeLogs < ActiveRecord::Migration
  def change
    add_column :department_change_logs, :employee_id, :integer, index: true
  end
end

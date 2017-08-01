class AddOldEmployeeNoToEmployees < ActiveRecord::Migration
  def change
    add_column :employees, :old_employee_no, :string
  end
end

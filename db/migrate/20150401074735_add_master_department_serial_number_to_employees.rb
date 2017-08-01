class AddMasterDepartmentSerialNumberToEmployees < ActiveRecord::Migration
  def change
    add_column :employees, :master_department_serial_number, :string
  end
end

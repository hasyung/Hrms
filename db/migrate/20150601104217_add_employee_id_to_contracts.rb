class AddEmployeeIdToContracts < ActiveRecord::Migration
  def change
    add_column :contracts, :employee_id, :integer
  end
end

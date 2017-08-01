class AddEmployeeNoToContracts < ActiveRecord::Migration
  def change
    add_column :contracts, :employee_no, :integer, default: 0
    add_column :contracts, :notes, :text
    add_index :contracts, :employee_no
  end
end

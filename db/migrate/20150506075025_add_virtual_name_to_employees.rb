class AddVirtualNameToEmployees < ActiveRecord::Migration
  def change
  	add_column :employees, :virtual_name, :string, index: true
  end
end

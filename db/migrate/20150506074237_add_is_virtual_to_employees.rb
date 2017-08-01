class AddIsVirtualToEmployees < ActiveRecord::Migration
  def change
  	add_column :employees, :is_virtual, :boolean, default: false, index: true
  end
end

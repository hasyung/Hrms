class DropFlowPermissions < ActiveRecord::Migration
  def change
    drop_table :flow_permissions

    remove_column :positions, :flow_bit_value
    remove_column :employees, :flow_bit_value

    remove_column :flows, :category
  end
end

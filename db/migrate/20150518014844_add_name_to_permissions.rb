class AddNameToPermissions < ActiveRecord::Migration
  def change
    add_column :permissions, :name, :string
  end
end

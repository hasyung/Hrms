class AddLevelToPermissions < ActiveRecord::Migration
  def change
    add_column :permissions, :level, :integer, index: true
  end
end

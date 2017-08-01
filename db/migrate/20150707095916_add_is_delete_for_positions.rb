class AddIsDeleteForPositions < ActiveRecord::Migration
  def change
    add_column :positions, :is_delete, :boolean, default: false, index: true
  end
end

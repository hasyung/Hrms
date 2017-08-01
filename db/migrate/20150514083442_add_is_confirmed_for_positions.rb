class AddIsConfirmedForPositions < ActiveRecord::Migration
  def change
    add_column :positions, :is_confirmed, :boolean, default: false
  end
end

class AddColumnsToPerformances < ActiveRecord::Migration
  def change
    add_column :performances, :department_id, :integer, index: true
    add_column :performances, :is_leader, :boolean, index: true
  end
end

class AddOperatorIdToPositionChangeRecord < ActiveRecord::Migration
  def change
    add_column :position_change_records, :operator_id, :integer, index: true
  end
end

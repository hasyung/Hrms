class AddLocationToPositionChangeRecords < ActiveRecord::Migration
  def change
    add_column :position_change_records, :location, :string, index: true, comment: '属地'
  end
end

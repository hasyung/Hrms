class ChangeColumnNameForPositionChangeRecords < ActiveRecord::Migration
  def change
    rename_column :position_change_records, :prabation_duration, :probation_duration
  end
end

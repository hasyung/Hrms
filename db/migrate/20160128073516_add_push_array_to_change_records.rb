class AddPushArrayToChangeRecords < ActiveRecord::Migration
  def change
    add_column :change_records, :ok_array, :text
    add_column :change_records, :failed_array, :text
  end
end

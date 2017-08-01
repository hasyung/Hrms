class ChangeColumnsForChangeRecords < ActiveRecord::Migration
  def change
    change_column :change_records, :is_pushed, :boolean, index: true, default: false
    change_column :change_records, :push_times, :integer, default: 0 
  end
end

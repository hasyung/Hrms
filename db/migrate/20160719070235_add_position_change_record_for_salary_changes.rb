class AddPositionChangeRecordForSalaryChanges < ActiveRecord::Migration
  def change
  	add_column :salary_changes, :position_change_record_id, :integer, index: true

  	add_column :position_change_records, :prev_category_id, :integer, index: true
  	add_column :position_change_records, :prev_department_name, :string, index: true
  	add_column :position_change_records, :prev_position_name, :string, index: true
  	add_column :position_change_records, :prev_location, :string, index: true
  end
end

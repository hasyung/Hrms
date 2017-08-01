class AddPrevDepartmentIdToPositionChangeRecords < ActiveRecord::Migration
  def change
    add_column :position_change_records, :prev_department_id, :integer, index: true
  end
end

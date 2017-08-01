class AddSalaryWillChangeToPositionChangeRecords < ActiveRecord::Migration
  def change
    add_column :position_change_records, :salary_will_change, :boolean, default: false, index: true
  end
end

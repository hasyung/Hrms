class AddEmployeeIdToRewardRecords < ActiveRecord::Migration
  def change
    add_column :reward_records, :employee_id, :integer, default: 0, index: true, comment: '员工id'
  end
end

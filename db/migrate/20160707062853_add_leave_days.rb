class AddLeaveDays < ActiveRecord::Migration
  def change
    add_column :employees, :leave_days, :integer, default: 0, index: true, comment: '离开川航天数'
  end
end

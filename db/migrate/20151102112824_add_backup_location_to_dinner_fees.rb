class AddBackupLocationToDinnerFees < ActiveRecord::Migration
  def change
    add_column :dinner_fees, :backup_location, :string, index: true, comment: '计算备份餐的时候员工的备份地'
  end
end

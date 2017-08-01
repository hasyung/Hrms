class AddBackupToDinnerFees < ActiveRecord::Migration
  def change
    add_column :dinner_fees, :backup, :decimal, precision: 10, scale: 2, index: true, comment: '备份餐'
  end
end

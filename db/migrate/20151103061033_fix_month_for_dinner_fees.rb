class FixMonthForDinnerFees < ActiveRecord::Migration
  def change
    rename_column :dinner_fees, :month, :meal_card_month
    add_column :dinner_fees, :working_month, :string, index: true, comment: '误餐费月份'
    add_column :dinner_fees, :backup_month, :string, index: true, comment: '备份餐月份'
  end
end

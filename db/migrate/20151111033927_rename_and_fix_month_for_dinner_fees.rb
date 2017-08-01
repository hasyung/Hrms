class RenameAndFixMonthForDinnerFees < ActiveRecord::Migration
  def change
    remove_column :dinner_fees, :meal_card_month
    remove_column :dinner_fees, :working_month
    remove_column :dinner_fees, :backup_month
    add_column :dinner_fees, :month, :string, index: true

    remove_column :dinner_settles, :meal_card_month
    remove_column :dinner_settles, :working_month
    remove_column :dinner_settles, :backup_month
    add_column :dinner_settles, :month, :string, index: true
  end
end

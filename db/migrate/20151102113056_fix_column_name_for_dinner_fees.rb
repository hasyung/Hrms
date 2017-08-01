class FixColumnNameForDinnerFees < ActiveRecord::Migration
  def change
    rename_column :dinner_fees, :backup, :backup_fee
  end
end

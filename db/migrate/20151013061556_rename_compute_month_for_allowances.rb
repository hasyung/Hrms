class RenameComputeMonthForAllowances < ActiveRecord::Migration
  def change
    rename_column :allowances, :compute_month, :month
    remove_column :allowances, :compute_date
  end
end

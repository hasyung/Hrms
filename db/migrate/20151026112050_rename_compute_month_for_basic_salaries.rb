class RenameComputeMonthForBasicSalaries < ActiveRecord::Migration
  def change
    rename_column :basic_salaries, :compute_month, :month
    remove_column :basic_salaries, :compute_date
  end
end

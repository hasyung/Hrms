class FixMonthDistributeBaseForEmployees < ActiveRecord::Migration
  def change
    change_column :employees, :month_distribute_base, :decimal, precision: 10, scale: 2, index: true
  end
end

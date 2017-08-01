class AddMonthDistributeBaseToEmployees < ActiveRecord::Migration
  def change
    add_column :employees, :month_distribute_base, :decimal, precision: 10, scale: 2, default: 0
    add_column :employees, :pcategory, :string
    add_index :employees, :pcategory
  end
end

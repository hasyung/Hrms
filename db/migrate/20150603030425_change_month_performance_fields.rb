class ChangeMonthPerformanceFields < ActiveRecord::Migration
  def change
    change_column :performances, :department_distribute_result, :decimal, precision: 15, scale: 2
    change_column :performances, :month_distribute_base, :decimal, precision: 10, scale: 2
    change_column :performances, :department_reserved, :decimal, precision: 15, scale: 2
  end
end

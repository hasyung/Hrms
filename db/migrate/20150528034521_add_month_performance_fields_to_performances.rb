class AddMonthPerformanceFieldsToPerformances < ActiveRecord::Migration
  def change
    add_column :performances, :department_distribute_result, :decimal
    add_column :performances, :month_distribute_base, :decimal
    add_column :performances, :department_reserved, :decimal
  end
end

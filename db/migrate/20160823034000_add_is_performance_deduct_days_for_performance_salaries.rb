class AddIsPerformanceDeductDaysForPerformanceSalaries < ActiveRecord::Migration
  def change
  	add_column :performance_salaries, :is_performance_deduct_days, :boolean, default: false, index: true, comment: '当前绩效是否被抵扣'
  end
end

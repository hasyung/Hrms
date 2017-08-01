class AddBasePerformanceMoneyToSalaryPersonSetups < ActiveRecord::Migration
  def change
    add_column :salary_person_setups, :base_performance_money, :decimal, precision: 10, scale: 2, index: true, comment: '对于服务b来说该字段是base和performance的和'
  end
end

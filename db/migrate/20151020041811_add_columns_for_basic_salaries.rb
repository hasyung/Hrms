class AddColumnsForBasicSalaries < ActiveRecord::Migration
  def change
    add_column :basic_salaries, :standard, :decimal, precision: 10, scale: 2, index: true, comment: '标准'
    add_column :basic_salaries, :deduct_money, :decimal, precision: 10, scale: 2, index: true, comment: '补扣项目'
  end
end

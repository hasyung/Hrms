class AddTotalToSalaryTable < ActiveRecord::Migration
  def change
    add_column :basic_salaries, :total, :decimal, precision: 10, scale: 2, index: true, comment: '小合计'
    add_column :keep_salaries, :total, :decimal, precision: 10, scale: 2, index: true, comment: '小合计'
    add_column :performance_salaries, :total, :decimal, precision: 10, scale: 2, index: true, comment: '小合计'
    add_column :allowances, :total, :decimal, precision: 10, scale: 2, index: true, comment: '小合计'
    add_column :land_allowances, :total, :decimal, precision: 10, scale: 2, index: true, comment: '小合计'
    add_column :rewards, :total, :decimal, precision: 10, scale: 2, index: true, comment: '小合计'
    add_column :transport_fees, :total, :decimal, precision: 10, scale: 2, index: true, comment: '小合计'
  end
end

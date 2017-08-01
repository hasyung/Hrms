class AddAnyColumnsForPerformanceSalaries < ActiveRecord::Migration
  def change
    remove_column :performance_salaries, :performance_money

    add_column    :performance_salaries, :result, :string, index: true, comment: '考核结果'
    add_column    :performance_salaries, :coefficient, :decimal, precision: 10, scale: 2, index: true, comment: '系数'
    add_column    :performance_salaries, :summary_deduct, :decimal, precision: 10, scale: 2, index: true, comment: '考勤扣款'
  end
end

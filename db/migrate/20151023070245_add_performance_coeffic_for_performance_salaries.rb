class AddPerformanceCoefficForPerformanceSalaries < ActiveRecord::Migration
  def change
    add_column :performance_salaries, :performance_coeffic, :decimal, precision: 10, scale: 3, index: true, comment: '公司效益指标系数'
    add_column :performance_salaries, :summary_days, :float, index: true, comment: '考勤扣款天数'
    add_column :performance_salaries, :cardinal, :decimal, precision: 10, scale: 2, index: true, comment: '考勤/处分扣款前基数'
    add_column :performance_salaries, :refund_fee, :decimal, precision: 10, scale: 2, index: true, comment: "费用化报销"
  end
end

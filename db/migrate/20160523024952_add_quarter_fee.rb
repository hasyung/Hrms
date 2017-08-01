class AddQuarterFee < ActiveRecord::Migration
  def change
    rename_column :department_salaries, :quarter_fee, :passenger_quarter_fee
    rename_column :rewards, :quarter_fee, :passenger_quarter_fee
    rename_column :reward_records, :quarter_fee, :passenger_quarter_fee

    add_column :department_salaries, :freight_quality_fee, :decimal, precision: 10, scale: 2, index: true, comment: "货运目标责任书季度奖"
    add_column :rewards, :freight_quality_fee, :decimal, precision: 10, scale: 2, index: true, comment: "货运目标责任书季度奖"
    add_column :reward_records, :freight_quality_fee, :decimal, precision: 10, scale: 2, index: true, comment: "货运目标责任书季度奖"
  end
end

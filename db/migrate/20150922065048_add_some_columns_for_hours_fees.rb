class AddSomeColumnsForHoursFees < ActiveRecord::Migration
  def change
    add_column :hours_fees, :up_or_down, :string, index: true, comment: "上浮下靠"
    add_column :hours_fees, :up_or_down_money, :decimal, precision: 10, scale: 2, index: true, comment: "上浮下靠金额"
    add_column :hours_fees, :performance_revenue, :decimal, precision: 10, scale: 2, index: true, comment: "考核性收入分配结果"
    add_column :hours_fees, :fertility_allowance, :decimal, precision: 10, scale: 2, index: true, comment: "生育津贴"
    add_column :hours_fees, :ground_subsidy, :decimal, precision: 10, scale: 2, index: true, comment: "地面兼职补贴"

    add_column :hours_fees, :hours_fee_category, :string, comment: "小时费人员类别"
  end
end

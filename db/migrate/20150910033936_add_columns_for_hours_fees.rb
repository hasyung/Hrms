class AddColumnsForHoursFees < ActiveRecord::Migration
  def change
    add_column :salary_person_setups, :refund_fee, :decimal, precision: 10, scale: 2, index: true, comment: "费用化报销"

    add_column :hours_fees, :reality_fly_hours, :decimal, precision: 10, scale: 2, index: true, comment: "实际飞行时间(职业晋升)"
    add_column :hours_fees, :total_hours_fee, :decimal, precision: 10, scale: 2, index: true, comment: "小时费合计"
    add_column :hours_fees, :total_security_fee, :decimal, precision: 10, scale: 2, index: true, comment: "安全合计"
    add_column :hours_fees, :hours_fee_difference, :decimal, precision: 10, scale: 2, index: true, comment: "小时费补差"
    add_column :hours_fees, :security_fee_difference, :decimal, precision: 10, scale: 2, index: true, comment: "安飞奖补差"
    add_column :hours_fees, :not_fly_subsidy, :decimal, precision: 10, scale: 2, index: true, comment: "未飞补贴"
    add_column :hours_fees, :lerder_subsidy, :decimal, precision: 10, scale: 2, index: true, comment: "干部津贴"
    add_column :hours_fees, :refund_fee, :decimal, precision: 10, scale: 2, index: true, comment: "费用化报销"
  end
end

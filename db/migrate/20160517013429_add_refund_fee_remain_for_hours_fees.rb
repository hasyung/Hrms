class AddRefundFeeRemainForHoursFees < ActiveRecord::Migration
  def change
  	add_column :hours_fees, :refund_fee_remain, :decimal, precision: 10, scale: 2, default: 0, index: true, comment: '费用化报销留存'
  end
end

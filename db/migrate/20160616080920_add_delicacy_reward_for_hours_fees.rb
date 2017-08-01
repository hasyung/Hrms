class AddDelicacyRewardForHoursFees < ActiveRecord::Migration
  def change
  	add_column :hours_fees, :delicacy_reward, :decimal, precision: 10, scale: 2, index: true, default:0, comment: "空勤精编奖励"
  end
end

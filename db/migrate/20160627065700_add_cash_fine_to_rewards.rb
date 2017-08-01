class AddCashFineToRewards < ActiveRecord::Migration
  def change
    add_column :rewards, :cash_fine_fee, :decimal, precision: 10, scale: 2, index: true, comment: "经济型扣罚"
    add_column :reward_records, :cash_fine_fee, :decimal, precision: 10, scale: 2, index: true, comment: "经济型扣罚"
  end
end

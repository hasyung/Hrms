class SplitAirlineFee < ActiveRecord::Migration
  def change
    add_column :airline_fees, :airline_fee_cash, :decimal, precision: 10, scale: 2, default: 0, index: true, comment: "空勤灶-现金"
    add_column :airline_fees, :airline_fee_card, :decimal, precision: 10, scale: 2, default: 0, index: true, comment: "空勤灶-饭卡"
  end
end

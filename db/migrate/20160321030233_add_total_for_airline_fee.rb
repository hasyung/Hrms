class AddTotalForAirlineFee < ActiveRecord::Migration
  def change
    add_column :airline_fees, :total_fee, :decimal, precision: 10, scale: 2, default: 0, index: true, comment: "总计"
  end
end

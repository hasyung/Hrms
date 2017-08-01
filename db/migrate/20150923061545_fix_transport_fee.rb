class FixTransportFee < ActiveRecord::Migration
  def change
    rename_column :transport_fees, :in_out_amount, :add_garnishee
    rename_column :transport_fees, :bus_fee_deduct_amount, :bus_fee
  end
end

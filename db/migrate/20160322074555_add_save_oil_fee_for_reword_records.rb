class AddSaveOilFeeForRewordRecords < ActiveRecord::Migration
  def change
    add_column :reward_records, :save_oil_fee, :decimal, precision: 10, scale: 2, index: true
    add_column :rewards, :save_oil_fee, :decimal, precision: 10, scale: 2, index: true
  end
end

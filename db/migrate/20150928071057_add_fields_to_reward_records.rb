class AddFieldsToRewardRecords < ActiveRecord::Migration
  def change
    add_column :reward_records, :flight_bonus, :decimal, precision: 10, scale: 2, index: true
    add_column :reward_records, :service_bonus, :decimal, precision: 10, scale: 2, index: true
    add_column :reward_records, :ailine_security_bonus, :decimal, precision: 10, scale: 2, index: true
    add_column :reward_records, :composite_bonus, :decimal, precision: 10, scale: 2, index: true
    add_column :reward_records, :insurance_proxy, :decimal, precision: 10, scale: 2, index: true
    add_column :reward_records, :cabin_grow_up, :decimal, precision: 10, scale: 2, index: true
    add_column :reward_records, :full_sale_promotion, :decimal, precision: 10, scale: 2, index: true
    add_column :reward_records, :article_fee, :decimal, precision: 10, scale: 2, index: true
    add_column :reward_records, :all_right_fly, :decimal, precision: 10, scale: 2, index: true
    add_column :reward_records, :year_composite_bonus, :decimal, precision: 10, scale: 2, index: true
    add_column :reward_records, :move_perfect, :decimal, precision: 10, scale: 2, index: true
    add_column :reward_records, :security_special, :decimal, precision: 10, scale: 2, index: true
    add_column :reward_records, :dep_security_undertake, :decimal, precision: 10, scale: 2, index: true
    add_column :reward_records, :fly_star, :decimal, precision: 10, scale: 2, index: true
    add_column :reward_records, :year_all_right_fly, :decimal, precision: 10, scale: 2, index: true
    add_column :reward_records, :network_connect, :decimal, precision: 10, scale: 2, index: true
    add_column :reward_records, :quarter_fee, :decimal, precision: 10, scale: 2, index: true
    add_column :reward_records, :earnings_fee, :decimal, precision: 10, scale: 2, index: true
  end
end

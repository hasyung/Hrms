class FixRewardsFileds < ActiveRecord::Migration
  def change
    remove_column :rewards, :bonus_1
    add_column :rewards, :best_goods, :decimal, precision: 10, scale: 2, index: true
    add_column :rewards, :best_plan, :decimal, precision: 10, scale: 2, index: true
  end
end

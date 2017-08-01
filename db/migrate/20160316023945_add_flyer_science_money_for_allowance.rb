class AddFlyerScienceMoneyForAllowance < ActiveRecord::Migration
  def change
    add_column :allowances, :flyer_science_money, :decimal, precision: 10, scale: 2, default: 0, index: true, comment: '飞行驾驶技术津贴'
  end
end

class AddFieldsToDinnerSettles < ActiveRecord::Migration
  def change
    add_column :dinner_settles, :card_amount, :decimal, precision: 10, scale: 2, index: true, comment: '卡金额'
    add_column :dinner_settles, :card_number, :integer, index: true, comment: '卡次数'
    add_column :dinner_settles, :working_fee, :decimal, precision: 10, scale: 2, index: true, comment: '误餐费'
    add_column :dinner_settles, :backup_fee, :decimal, precision: 10, scale: 2, index: true, comment: '备份餐'
    add_column :dinner_settles, :subsidy_amount, :decimal, precision: 10, scale: 2, index: true, comment: '补贴'
    add_column :dinner_settles, :location, :string, index: true, comment: '驻地'
    add_column :dinner_settles, :total, :decimal, precision: 10, scale: 2, index: true, comment: '总计'
    add_column :dinner_settles, :meal_card_month, :string, index: true, comment: '发卡月份'
    add_column :dinner_settles, :working_month, :string, index: true, comment: '误餐费月份'
    add_column :dinner_settles, :backup_month, :string, index: true, comment: '备注月份'
  end
end

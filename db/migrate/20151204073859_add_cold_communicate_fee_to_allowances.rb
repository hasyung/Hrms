class AddColdCommunicateFeeToAllowances < ActiveRecord::Migration
  def change
    add_column :allowances, :cold, :decimal, precision: 10, scale: 2, default: 0, index: true, comment:'寒冷补贴'
    add_column :allowances, :communication, :decimal, precision: 10, scale: 2, default: 0, index: true, comment:'寒冷补贴'
  end
end

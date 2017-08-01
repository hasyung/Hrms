class AddOffBudgetFeeToRewards < ActiveRecord::Migration
  def change
    add_column :rewards, :off_budget_fee, :decimal, precision: 10, scale: 2, index: true, comment: '预算外奖励'
  end
end

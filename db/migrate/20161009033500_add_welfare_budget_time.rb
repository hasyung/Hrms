class AddWelfareBudgetTime < ActiveRecord::Migration
  def change
    add_column :welfare_budgets ,:created_at, :timestamp ,null:false
    add_column :welfare_budgets ,:updated_at, :timestamp ,null:false
  end
end

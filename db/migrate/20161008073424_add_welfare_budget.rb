class AddWelfareBudget < ActiveRecord::Migration
  def change
    create_table :welfare_budgets do |t|
      t.string  :year, null: false, index: true, comment: "年"
      t.string  :category, null: false, index: true, comment: "类型"
      t.decimal :fee, precision: 10, scale: 2, index: true, comment: "钱"
    end
  end
end

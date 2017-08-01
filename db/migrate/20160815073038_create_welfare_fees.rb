class CreateWelfareFees < ActiveRecord::Migration
  def change
    create_table :welfare_fees do |t|
    	t.string  :month, null: false, index: true, comment: "月" 
    	t.string  :category, null: false, index: true, comment: "类型" 
    	t.decimal :fee, precision: 10, scale: 2, index: true, comment: "钱"

      t.timestamps null: false
    end
  end
end

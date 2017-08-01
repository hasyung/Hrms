class CreateCodeTable < ActiveRecord::Migration
  def change
    create_table :code_tables do |t|
      t.string :name
      t.string :display_name
      t.string :type
      t.integer :level, default: 0 #表示显示层级

      t.timestamps null: false
    end
  end
end

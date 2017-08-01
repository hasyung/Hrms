class CreateNotification < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.string :category
      t.string :body
      t.boolean :confirmed, default: false
      t.time :confirmed_at
      t.integer :employee_id

      t.index :category
      t.index :confirmed
      t.index :confirmed_at
      t.index :employee_id

      t.timestamps null: false
    end
  end
end

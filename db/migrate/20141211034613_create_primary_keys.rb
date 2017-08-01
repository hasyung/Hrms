class CreatePrimaryKeys < ActiveRecord::Migration
  def change
    create_table :primary_keys do |t|
      t.string :name
      t.string :model
      t.integer :max_id, default: 0

      t.index :name

      t.timestamps null: false
    end
  end
end

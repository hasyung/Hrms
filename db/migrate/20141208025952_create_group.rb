class CreateGroup < ActiveRecord::Migration
  def change
    create_table :groups do |t|
      t.string :name
      t.string :description
      t.string :bit_value, default: '0'

      t.index :name
      t.index :bit_value

      t.timestamps null: false
    end
  end
end

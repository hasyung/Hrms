class CreateSnapshot < ActiveRecord::Migration
  def change
    create_table :snapshots do |t|
      t.string :model #模型
      t.integer :version, default: 0  #版本
      t.text :data  #数据

      t.index :model
      t.index :version

      t.timestamps null: false
    end
  end
end

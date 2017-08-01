class CreateSystemConfig < ActiveRecord::Migration
  def change
    create_table :system_configs do |t|
      t.string :key
      t.string :value

      t.timestamps null: false
    end
  end
end

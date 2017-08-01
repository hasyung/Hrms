class CreateCodeTableChannel < ActiveRecord::Migration
  def change
    create_table :code_table_channels do |t|
      t.string :name
      t.string :display_name

      t.timestamps null: false
    end
  end
end

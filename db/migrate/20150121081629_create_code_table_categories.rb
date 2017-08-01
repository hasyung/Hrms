class CreateCodeTableCategories < ActiveRecord::Migration
  def change
    create_table :code_table_categories do |t|
      t.string :name
      t.string :display_name
      t.string :key
      t.timestamps null: false
    end
  end
end

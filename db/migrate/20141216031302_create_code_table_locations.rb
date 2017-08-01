class CreateCodeTableLocations < ActiveRecord::Migration
  def change
    create_table :code_table_locations do |t|
      t.string :name 	#名称
      t.string :display_name

      t.timestamps null: false
    end
  end
end

class CreateChangeRecords < ActiveRecord::Migration
  def change
    create_table :change_records do |t|
      t.string :change_type, index: true 
      t.datetime :event_time, index: true 
      t.boolean :is_pushed, index: true 
      t.integer :push_times
      t.text :change_data

      t.timestamps null: false
    end
  end
end

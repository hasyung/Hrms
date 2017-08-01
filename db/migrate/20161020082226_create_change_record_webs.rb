class CreateChangeRecordWebs < ActiveRecord::Migration
  def change
    create_table :change_record_webs do |t|
      t.string :change_type, index: true 
      t.datetime :event_time, index: true 
      t.boolean :is_pushed, index: true, default: false 
      t.integer :push_times, default: 0
      t.text :change_data
      t.text :ok_array
      t.text :failed_array

      t.timestamps null: false
    end
  end
end

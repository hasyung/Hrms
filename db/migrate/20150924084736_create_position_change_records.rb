class CreatePositionChangeRecords < ActiveRecord::Migration
  def change
    create_table :position_change_records do |t|
      t.integer :employee_id, index: true
      t.integer :channel_id
      t.integer :category_id
      t.integer :duty_rank_id
      t.string  :position_remark
      t.string  :oa_file_no
      t.date    :position_change_date
      t.date    :probation_end_date
      t.integer :prabation_duration, default: 0
      t.boolean :is_finished, default: false, index: true
      t.text    :position_form

      t.timestamps null: false
    end
  end
end

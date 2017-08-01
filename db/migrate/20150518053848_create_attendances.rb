class CreateAttendances < ActiveRecord::Migration
  def change
    create_table :attendances do |t|
      t.string :record_type #迟到，早退，旷工
      t.date :record_date #只能按照每天的单位记录
      t.references :employee, index: true
      t.timestamps null: false
    end
  end
end

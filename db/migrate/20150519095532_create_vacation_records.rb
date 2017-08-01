class CreateVacationRecords < ActiveRecord::Migration
  def change
    create_table :vacation_records do |t|
      t.string :record_type, index: true, default: "年假"
      t.integer :days, default: 0, index: true
      t.references :employee, index: true
      t.string :year, index: true, default: "2015"
      t.timestamps null: false
    end
  end
end

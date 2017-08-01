class CreateHolidays < ActiveRecord::Migration
  def change
    create_table :holidays do |t|
      t.date :record_date, index: true
      t.integer :flag, default: 0
      t.timestamps null: false
    end
  end
end

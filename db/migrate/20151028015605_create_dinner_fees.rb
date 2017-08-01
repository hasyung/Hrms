class CreateDinnerFees < ActiveRecord::Migration
  def change
    create_table :dinner_fees do |t|
      t.integer :employee_id, default: 0, index: true
      t.string :employee_no, index: true
      t.string :employee_name, index: true
      t.string :shifts_type, index: true
      t.string :area, index: true
      t.integer :card_number, index: true
      t.decimal :card_amount, precision: 10, scale: 2, default: 0, index: true
      t.decimal :working_fee, precision: 10, scale: 2, default: 0, index: true
      t.string :month, index: true
      t.timestamps null: false
    end
  end
end

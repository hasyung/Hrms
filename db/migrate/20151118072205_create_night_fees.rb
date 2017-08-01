class CreateNightFees < ActiveRecord::Migration
  def change
    create_table :night_fees do |t|
      t.integer :employee_id, index: true
      t.string :employee_name, index: true
      t.string :shifts_type, index: true, comment: '班制'
      t.integer :night_number, default: 0, index: true, comment: '夜班次数'
      t.string :notes, comment: '备注'
      t.decimal :amount, default: 0, precision: 10, scale: 2, comment: '实发金额'
      t.string :flag, comment: '标识'
      t.string :month, index: true, comment: '计算月份'
      t.timestamps null: false
    end
  end
end

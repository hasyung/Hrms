class CreateTransportFees < ActiveRecord::Migration
  def change
    create_table :transport_fees do |t|
      t.integer :employee_id, index: true
      t.string :employee_no, index: true 
      t.string :employee_name, index: true
      t.string :department_name
      t.string :position_name
      t.decimal :amount, precision: 10, scal: 2, index: true, comment: '交通费'
      t.decimal :in_out_amount, precision: 10, scal: 2, index: true, comment: '补扣发'
      t.decimal :bus_fee_deduct_amount, precision: 10, scal: 2, index: true, comment: '班车费扣除'
      t.string :remark, comment: '备注'
      t.string :month, index: true, comment: '月份'

      t.timestamps null: false
    end
  end
end

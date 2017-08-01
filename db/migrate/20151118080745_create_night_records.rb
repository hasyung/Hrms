class CreateNightRecords < ActiveRecord::Migration
  def change
    create_table :night_records do |t|
      t.integer :no, index: true, comment: '序号'
      t.string :employee_no, index: true
      t.string :employee_name, index: true
      t.string :first_department, comment: '一级部门'
      t.string :shifts_type, index: true, comment: '班制'
      t.string :location, index: true, comment: '属地化'
      t.integer :night_number, default: 0, index: true, comment: '夜班次数'
      t.string :notes, comment: '备注'
      t.decimal :subsidy, precision: 10, scale: 2, default: 0, index: true, comment: '标准'
      t.decimal :amount, precision: 10, scale: 2, default: 0, index: true, comment: '实发'
      t.string :flag, comment: '标识符'
      t.string :month, index: true, comment: '计算月份'
      t.timestamps null: false
    end
  end
end

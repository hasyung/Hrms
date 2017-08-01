class CreateDinnerPersonSetups < ActiveRecord::Migration
  def change
    create_table :dinner_person_setups do |t|
      t.integer :employee_id, default: 0, index: true, comment: '员工id'
      t.string :employee_no, index: true, comment: '员工编号'
      t.string :employee_name, index: true, comment: '员工姓名'
      t.string :shifts_type, index: true, comment: '班制'
      t.string :chengduArea, index: true, comment: '成都区域'
      t.decimal :cardAmount, default: 0, precision: 10, scale: 2, index: true, comment: '卡金额'
      t.string :cardNumber, index: true, comment: '卡次数'
      t.decimal :dinnerfee, default: 0, precision: 10, scale: 2, index: true, comment: '餐费金额'
      t.timestamps null: false
    end
  end
end

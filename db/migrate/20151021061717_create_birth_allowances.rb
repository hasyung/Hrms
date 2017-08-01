class CreateBirthAllowances < ActiveRecord::Migration
  def change
    create_table :birth_allowances do |t|
      t.integer :employee_id, index: true, comment: '员工id'
      t.string :employee_no, index: true, comment: '员工编号'
      t.string :employee_name, index: true, comment: '员工姓名'
      t.string :department_name, comment: '部门'
      t.string :position_name, comment: '部门'
      t.date :sent_date, index: true, comment: '发放日期'
      t.decimal :sent_amount, precision: 10, scale: 2, default: 0, index: true, comment: '社保发放金额'
      t.decimal :deduct_amount, precision: 10, scale: 2, default: 0, index: true, comment: '抵扣金额'
      t.timestamps null: false
    end
  end
end

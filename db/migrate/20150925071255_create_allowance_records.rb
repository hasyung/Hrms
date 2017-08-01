class CreateAllowanceRecords < ActiveRecord::Migration
  def change
    create_table :allowance_records do |t|
      t.string :employee_name, index: true, comment: '员工姓名'
      t.string :employee_no, index: true, comment: '员工编号'
      t.decimal :airline_practice, index: true, precision: 10, scale: 2, comment: '航线实习补贴'
      t.decimal :follow_plane, index: true, precision: 10, scale: 2, comment: '随机补贴'
      t.decimal :permit_sign, index: true, precision: 10, scale: 2, comment: '签派放行补贴'
      t.decimal :work_overtime, index: true, precision: 10, scale: 2, comment: '梭班补贴'
      t.string :month, index: true, comment: '薪酬月份'
      t.timestamps null: false
    end
  end
end

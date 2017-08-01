class CreateLandRecords < ActiveRecord::Migration
  def change
    create_table :land_records do |t|
      t.string :employee_name, index: true, comment: '员工姓名'
      t.integer :days, default: 0, index: true, comment: '驻站天数'
      t.string :city, index: true, comment: '驻站城市'
      t.integer :start_day, index: true, comment: '起始日期'
      t.integer :end_day, index: true, comment: '起始日期'
      t.string :month, index: true, comment: '对应的薪酬月份'
      t.timestamps null: false
    end
  end
end

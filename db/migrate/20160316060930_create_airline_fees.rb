class CreateAirlineFees < ActiveRecord::Migration
  def change
    create_table :airline_fees do |t|
      t.integer :employee_id, index: true
      t.string :employee_no, comment: '人员编号'
      t.string :employee_name, index: true, comment: '人员名称'
      t.string :department_name, comment: '机构名称'
      t.string :position_name, comment: '岗位名称'
      t.string :month, index: true, comment: '计算日期'

      t.decimal :airline_fee, precision: 10, scale: 2, default: 0, index: true, comment: '空勤灶'
      t.decimal :oversea_food_fee, precision: 10, scale: 2, default: 0, index: true, comment: '境外餐食补贴'
      t.decimal :add_garnishee, precision: 10, scale: 2, default: 0, index: true, comment: '补扣发'

      t.string :remark, comment: '备注'
      t.text :note, comment: '计算过程备注'

      t.timestamps null: false
    end
  end
end

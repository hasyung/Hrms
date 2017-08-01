class CreateSecurityFees < ActiveRecord::Migration
  def change
    create_table :security_fees do |t|
    	t.integer :employee_id, index: true
      t.string :employee_no, comment: '人员编号'
      t.string :employee_name, index: true, comment: '人员名称'
      t.string :department_name, comment: '机构名称'
      t.string :position_name, comment: '岗位名称'
      t.string :month, index: true, comment: '月份'

      t.decimal :fee, precision: 10, scale: 2, default: 0, index: true, comment: '安飞奖'
      t.decimal :add_garnishee, precision: 10, scale: 2, default: 0, index: true, comment: '补扣发'
      t.decimal :total, precision: 10, scale: 2, default: 0, index: true, comment: '合计'
      t.string  :remark, comment: '备注'

      t.timestamps null: false
    end
  end
end

class CreateAllowances < ActiveRecord::Migration
  def change
    create_table :allowances do |t|
      t.integer :employee_id, null: false, index: true

      t.string  :compute_month, index: true, comment: '月度'
      t.date    :compute_date, index: true

      t.string  :employee_name, index: true, comment: '姓名'
      t.string  :employee_no, index: true, comment: '员工编码'
      t.string  :department_name, index: true, comment: '所属部门'
      t.string  :position_name, index: true, comment: '岗位'
      t.integer :channel_id, index: true, comment: '通道ID'

      t.decimal :subsidy, index: true, comment: '津贴'
      t.decimal :add_garnishee, comment: '补扣发'
      t.string  :remark, comment: '备注'

      t.timestamps null: false
    end
  end
end

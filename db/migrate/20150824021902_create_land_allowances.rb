class CreateLandAllowances < ActiveRecord::Migration
  def change
    create_table :land_allowances do |t|
      t.string :employee_no, index: true, comment: "员工编码"
      t.string :employee_name, index: true, comment: "姓名"
      t.string :department_name, comment: "所属部门"
      t.string :position_name, comment: "岗位"
      t.string :remark, comment: "备注"
      t.string :month, index: true, comment: "计算日期"

      t.integer :channel_id, index: true, comment: "人员通道"
      t.integer :employee_id, index: true

      t.decimal :subsidy, index: true, comment: "津贴"
      t.decimal :add_garnishee, comment: "补扣发"

      t.timestamps null: false
    end
  end
end

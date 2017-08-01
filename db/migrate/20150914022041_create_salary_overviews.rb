class CreateSalaryOverviews < ActiveRecord::Migration
  def change
    create_table :salary_overviews do |t|
      t.string :employee_no, comment: "人员编号"
      t.string :employee_name, index: true, comment: "人员名称"
      t.string :department_name, comment: "机构名称"
      t.string :position_name, comment: "岗位名称"
      t.string :month, index: true, comment: "薪酬合计计算日期"
      t.string :remark, comment: "备注"

      t.integer :channel_id, index: true, comment: "人员通道"
      t.integer :employee_id, index: true

      t.decimal :base, precision: 10, scale: 2, index: true, comment: "基础薪酬"
      t.decimal :performance, precision: 10, scale: 2, index: true, comment: "绩效薪酬"
      t.decimal :hours_fee, precision: 10, scale: 2, index: true, comment: "小时费"
      t.decimal :subdidy, precision: 10, scale: 2, index: true, comment: "津贴"
      t.decimal :land_subdidy, precision: 10, scale: 2, index: true, comment: "驻站津贴"
      t.decimal :reward, precision: 10, scale: 2, index: true, comment: "奖励"
      t.decimal :total, precision: 10, scale: 2, index: true, comment: "薪酬合计"

      t.timestamps null: false
    end
  end
end

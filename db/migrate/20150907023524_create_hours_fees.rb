class CreateHoursFees < ActiveRecord::Migration
  def change
    create_table :hours_fees do |t|
      t.string :employee_no, comment: "人员编号"
      t.string :employee_name, index: true, comment: "人员名称"
      t.string :department_name, comment: "机构名称"
      t.string :position_name, comment: "岗位名称"
      t.string :month, index: true, comment: "小时费计算日期"
      t.string :remark, comment: "备注"

      t.integer :channel_id, index: true, comment: "人员通道"
      t.integer :employee_id, index: true

      t.decimal :fly_hours, precision: 10, scale: 2, index: true, comment: "飞行时间"
      t.decimal :fly_fee, precision: 10, scale: 2, index: true, comment: "小时费"
      t.decimal :airline_fee, precision: 10, scale: 2, index: true, comment: "空勤灶"
      t.decimal :add_garnishee, precision: 10, scale: 2, index: true, comment: "补扣发"

      t.timestamps null: false
    end

    add_column :salary_person_setups, :is_salary_special, :boolean, default: false, comment: "是否是特殊薪酬人员"
    add_column :employees, :hours_fee_category, :string, comment: "小时费人员类别"
  end
end

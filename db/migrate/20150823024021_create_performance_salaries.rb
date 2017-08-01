class CreatePerformanceSalaries < ActiveRecord::Migration
  def change
    create_table :performance_salaries do |t|
      t.string :employee_no, comment: "人员编号"
      t.string :employee_name, index: true, comment: "人员名称"
      t.string :department_name, comment: "机构名称"
      t.string :position_name, comment: "岗位名称"
      t.string :month, index: true, comment: "绩效薪酬计算日期"
      t.string :remark, comment: "备注"

      t.integer :channel_id, index: true, comment: "人员通道"
      t.integer :employee_id, index: true

      t.decimal :base_salary, index: true, comment: "当月绩效基数"
      t.decimal :amount, index: true, comment: "当月绩效薪酬"
      t.decimal :add_garnishee, index: true, comment: "补扣发"
    end
  end
end

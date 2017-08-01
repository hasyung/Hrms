class CreateContracts < ActiveRecord::Migration
  def change
    create_table :contracts do |t|
      t.string :department_name, index: true
      t.string :position_name, index: true
      t.string :employee_name, index: true
      t.string :apply_type, index: true  # 用工性质 合同制/合同
      t.string :change_flag, index: true # 变更标志
      t.string :contract_no, index: true # 合同号，等于员工编号
      t.integer :due_time, index: true   # 合同期限 年份/固定(单位: 年)
      t.date :start_date, index: true    # 起始日期
      t.date :end_date, index: true      # 终止日期
      t.date :join_date, index: true     # 到岗日期
      t.string :status, index: true      # 劳动关系状态
      t.boolean :employee_exists, index: true
      t.timestamps null: false
    end
  end
end

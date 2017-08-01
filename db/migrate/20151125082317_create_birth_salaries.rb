class CreateBirthSalaries < ActiveRecord::Migration
  def change
    create_table :birth_salaries do |t|
      t.integer :employee_id, null: false, index: true

      t.string  :month, index: true, comment: '月度'

      t.string  :employee_name, index: true, comment: '姓名'
      t.string  :employee_no, index: true, comment: '员工编码'
      t.string  :department_name, index: true, comment: '所属部门'
      t.string  :position_name, index: true, comment: '岗位'
      t.integer :channel_id, index: true, comment: '通道ID'

      t.decimal :basic_salary, precision: 10, scale: 2, index: true, comment: '基本工资'
      t.decimal :working_years_salary, precision: 10, scale: 2, index: true, comment: '工龄工资'
      t.decimal :keep_salary, precision: 10, scale: 2, index: true, comment: '保留工资'
      t.decimal :performance_salary, precision: 10, scale: 2, index: true, comment: '绩效薪酬'
      t.decimal :hours_fee, precision: 10, scale: 2, index: true, comment: '小时费'
      t.decimal :budget_reward, precision: 10, scale: 2, index: true, comment: '收支目标考核奖'
      t.decimal :transport_fee, precision: 10, scale: 2, index: true, comment: '交通费'
      t.decimal :temp_allowance, precision: 10, scale: 2, index: true, comment: '高温津贴'
      t.decimal :residue_money, precision: 10, scale: 2, index: true, comment: '剩余抵扣金额'
      t.decimal :birth_residue_money, precision: 10, scale: 2, index: true, comment: '生育保险冲抵'
      t.decimal :after_residue_money, precision: 10, scale: 2, index: true, comment: '当期抵扣后剩余'

      t.string  :remark, comment: '备注'
      t.text    :notes, comment: '系统备注'

      t.timestamps null: false
    end

    add_column :employees, :personal_reserved_funds, :decimal, precision: 10, scale: 2, index: true, comment: '公积金个人部分'
  end
end

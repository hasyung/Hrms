class CreateCalcSteps < ActiveRecord::Migration
  def change
    create_table :calc_steps do |t|
      t.references :employee, index: true, comment: '员工外键'
      t.string :month, index: true, comment: '计算工资的月份'
      t.string :category, index: true, comment: '计算的薪酬种类(en)，比如基础薪酬(basic_salary)，绩效薪酬(performance_salary)，小时费(hours_fee)，津贴(allowance)，驻站津贴(land_allowance)，奖励(reward)，交通费(transport_fee)，合计(salary_overview)'
      t.text :step_notes, comment: '计算过程'
      t.decimal :amount, precision: 10, scale: 2, comment: '计算结果'
      t.timestamps null: false
    end
  end
end

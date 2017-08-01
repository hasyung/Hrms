class AddColumnsForPerformanceSalaries < ActiveRecord::Migration
  def change
    add_column :performance_salaries, :performance_money, :decimal, precision: 10, scale: 2, index: true, comment: "上传回来的绩效薪酬金额"

    add_column :departments, :remain, :decimal, precision: 10, scale: 2, default: 0, index: true, comment: "总留存"
    add_column :departments, :leader_remain, :decimal, precision: 10, scale: 2, default: 0, index: true, comment: "干部留存"
    add_column :departments, :employee_remain, :decimal, precision: 10, scale: 2, default: 0, index: true, comment: "员工留存"
  end
end

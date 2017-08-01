class AddIsStopSalaryToEmployees < ActiveRecord::Migration
  def change
    add_column :employees, :is_stop_salary, :boolean, default: false, index: true, comment: '表示是否处于停薪调状态'
  end
end

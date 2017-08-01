class AddAnyColumnsForSalaryPersonSetups < ActiveRecord::Migration
  def change
    add_column :salary_person_setups, :is_service_fly, :boolean, default: false, index: true, comment: '是否为空勤飞行'
    add_column :salary_person_setups, :is_service_land, :boolean, default: false, index: true, comment: '是否为空勤地面'

    add_column :performance_salaries, :department_distribute, :decimal, precision: 10, scale: 2, default: 0, index: true, comment: "部门当月分配结果"
    add_column :performance_salaries, :department_reserved, :decimal, precision: 10, scale: 2, default: 0, index: true, comment: "部门留存分配结果"
  end
end

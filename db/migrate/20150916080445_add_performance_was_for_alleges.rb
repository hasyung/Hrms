class AddPerformanceWasForAlleges < ActiveRecord::Migration
  def change
    add_column :performance_alleges, :performance_was, :string

    add_column :salary_person_setups, :double_department_check, :boolean, default: false, index: true, comment: "双部门考核"
    add_column :salary_person_setups, :second_department_id, :integer, index: true, comment: "第二考核部门"
    add_column :salary_person_setups, :official_car, :decimal, precision: 10, scale: 2, index: true, comment: "公务车报销额度"
    add_column :salary_person_setups, :lowest_fly_time, :float, index: true, comment: "最低飞行时间"
    add_column :salary_person_setups, :lowest_calc_time, :float, index: true, comment: "最低计费时间"
    add_column :salary_person_setups, :leader_subsidy_time, :float, index: true, comment: "干部补贴飞行时间"
    add_column :salary_person_setups, :fly_check_lifecycle, :string, comment: "飞行时限考核周期"
  end
end

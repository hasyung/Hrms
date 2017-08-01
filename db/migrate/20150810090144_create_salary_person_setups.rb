class CreateSalaryPersonSetups < ActiveRecord::Migration
  def change
    create_table :salary_person_setups do |t|
      t.integer :employee_id, null: false, index: true, comment: "员工ID"

      t.string  :employee_no, index: true, comment: "员工编码"
      t.string  :employee_name, index: true, comment: "姓名"
      t.string  :department_name, index: true, comment: "所属部门"
      t.string  :position_name, index: true, comment: "岗位"

      t.string  :base_wage, index: true, comment: "基础工资"
      t.string  :base_channel, index: true, comment: "薪酬通道"
      t.string  :base_flag, index: true, comment: "基础档级"
      t.integer :reserve_wage, comment: "保留工资"

      t.string  :performance_wage, index: true, comment: "绩效工资"
      t.string  :performance_flag, index: true, comment: "绩效档级"

      t.string  :security_subsidy, index: true, comment: "安检津贴"
      t.string  :leader_subsidy, index: true, comment: "班组长津贴"
      t.string  :terminal_subsidy, index: true, comment: "航站管理津贴"
      t.string  :ground_subsidy, index: true, comment: "地勤补贴"
      t.string  :machine_subsidy, index: true, comment: "机务放行补贴"
      t.string  :trial_subsidy, index: true, comment: "试车津贴"
      t.string  :honor_subsidy, index: true, comment: "飞行安全荣誉津贴"

      t.boolean :placement_subsidy, default: false, index: true, comment: "安检津贴"
      t.boolean :car_subsidy, default: false, index: true, comment: "车勤补贴"

      t.boolean :is_stop, default: false, index: true, comment: "是否停薪"

      t.timestamps null: false
    end
  end
end

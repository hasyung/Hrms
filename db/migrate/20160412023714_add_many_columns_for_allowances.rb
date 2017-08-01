class AddManyColumnsForAllowances < ActiveRecord::Migration
  def change
  	add_column :allowances, :watch_subsidy, :decimal, precision: 10, scale: 2, index: true, comment: '值班工资'
    add_column :allowances, :logistical_support_subsidy, :decimal, precision: 10, scale: 2, index: true, comment: '后勤保障部补贴'

    add_column :salary_person_setups, :watch_subsidy, :boolean, default: false, index: true, comment: "值班工资"
    add_column :salary_person_setups, :logistical_support_subsidy, :boolean, default: false, index: true, comment: "值班工资"
  end
end

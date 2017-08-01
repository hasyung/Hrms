class AddSomeColumnsForSalaryPersonSetups < ActiveRecord::Migration
  def change
    add_column :salary_person_setups, :leader_grade, :string, index: true, comment: '干部岗位薪酬等级'
    add_column :salary_person_setups, :lower_limit_hour, :string, index: true, comment: '最低飞行时间'
    add_column :salary_person_setups, :leader_subsidy_hour, :string, index: true, comment: '干部补贴飞行时间'
    add_column :salary_person_setups, :technical_grade, :string, index: true, comment: '专业技术等级'

    remove_column :hours_fees, :security_fee_difference
    remove_column :hours_fees, :not_fly_subsidy
  end
end

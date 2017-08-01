class AddMoneyForSalaryPersonSetups < ActiveRecord::Migration
  def change
    add_column :salary_person_setups, :base_money, :integer, default: 0, index: true, comment: "基础金额"
    add_column :salary_person_setups, :performance_money, :integer, default: 0, index: true, comment: "绩效金额"
  end
end

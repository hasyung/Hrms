class AddAllowancesForSalaryPersonSetups < ActiveRecord::Migration
  def change
    add_column :salary_person_setups, :temp_allowance, :decimal, precision: 10, scale: 2, index: true, comment: "高温补贴"
    add_column :salary_person_setups, :communicate_allowance, :decimal, precision: 10, scale: 2, index: true, comment: "通讯补贴"
  end
end

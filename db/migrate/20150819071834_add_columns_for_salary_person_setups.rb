class AddColumnsForSalaryPersonSetups < ActiveRecord::Migration
  def change
    add_column :salary_person_setups, :fly_hour_fee, :string, index: true, comment: "小时费"
    add_column :salary_person_setups, :fly_hour_money, :integer, default: 0, comment: "小时费标准"

    add_column :salary_person_setups, :airline_hour_fee, :string, index: true, comment: "空乘小时费"
    add_column :salary_person_setups, :airline_hour_money, :integer, default: 0, comment: "空乘小时费标准"

    add_column :salary_person_setups, :security_hour_fee, :string, index: true, comment: "空保小时费"
    add_column :salary_person_setups, :security_hour_money, :integer, default: 0, comment: "空保小时费标准"

    add_column :salary_person_setups, :land_type, :string, index: true, comment: "驻站类型"

    add_column :salary_person_setups, :limit_leader, :boolean, default: false, index: true, comment: "是否飞行受限干部"
  end
end

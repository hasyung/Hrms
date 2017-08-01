class AddAnyColumnsForAllowances < ActiveRecord::Migration
  def change
    add_column :allowances, :part_permit_entry_standard, :decimal, precision: 10, scale: 2, index: true, comment: "部件放行补贴标准"
    add_column :allowances, :part_permit_entry, :decimal, precision: 10, scale: 2, index: true, comment: "部件放行补贴"
    add_column :allowances, :resettlement_standard, :decimal, precision: 10, scale: 2, index: true, comment: "安置津贴标准"
    add_column :allowances, :fly_honor_standard, :decimal, precision: 10, scale: 2, index: true, comment: "飞行荣誉津贴标准"
    add_column :allowances, :communication_standard, :decimal, precision: 10, scale: 2, index: true, comment: "通讯补贴标准"

    add_column :salary_person_setups, :part_permit_entry, :boolean, default: false, index: true, comment: "部件放行补贴"
  end
end

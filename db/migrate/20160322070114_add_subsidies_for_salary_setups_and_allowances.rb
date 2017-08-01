class AddSubsidiesForSalarySetupsAndAllowances < ActiveRecord::Migration
  def change
    add_column :salary_person_setups, :building_subsidy, :decimal, precision: 10, scale: 2, index: true, comment: "大厦补贴"
    add_column :salary_person_setups, :on_duty_subsidy, :decimal, precision: 10, scale: 2, index: true, comment: "执勤补贴"
    add_column :salary_person_setups, :retiree_clean_fee, :decimal, precision: 10, scale: 2, index: true, comment: "退休人员清洁费"
    add_column :salary_person_setups, :maintain_subsidy, :decimal, precision: 10, scale: 2, index: true, comment: "维修补贴"

    add_column :allowances, :building_subsidy, :decimal, precision: 10, scale: 2, index: true, comment: "大厦补贴"
    add_column :allowances, :on_duty_subsidy, :decimal, precision: 10, scale: 2, index: true, comment: "执勤补贴"
    add_column :allowances, :import_on_duty_subsidy, :decimal, precision: 10, scale: 2, index: true, comment: "导入执勤补贴"
    add_column :allowances, :retiree_clean_fee, :decimal, precision: 10, scale: 2, index: true, comment: "退休人员清洁费"
    add_column :allowances, :maintain_subsidy, :decimal, precision: 10, scale: 2, index: true, comment: "维修补贴"
    add_column :allowances, :property_subsidy, :decimal, precision: 10, scale: 2, index: true, comment: "物业补贴"
    add_column :allowances, :with_parking_subsidy, :decimal, precision: 10, scale: 2, index: true, comment: "带泊车补贴"
    add_column :allowances, :annual_audit_subsidy, :decimal, precision: 10, scale: 2, index: true, comment: "年审补贴"
  end
end

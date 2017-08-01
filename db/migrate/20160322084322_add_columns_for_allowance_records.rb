class AddColumnsForAllowanceRecords < ActiveRecord::Migration
  def change
  	add_column :allowance_records, :import_on_duty_subsidy, :decimal, precision: 10, scale: 2, index: true, comment: "导入执勤补贴"
  	add_column :allowance_records, :property_subsidy, :decimal, precision: 10, scale: 2, index: true, comment: "物业补贴"
  	add_column :allowance_records, :with_parking_subsidy, :decimal, precision: 10, scale: 2, index: true, comment: "带泊车补贴"
  	add_column :allowance_records, :annual_audit_subsidy, :decimal, precision: 10, scale: 2, index: true, comment: "年审补贴"
  end
end

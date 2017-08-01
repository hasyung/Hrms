class AddSomeColumnsForAllowances < ActiveRecord::Migration
  def change
  	add_column :allowances, :security_check_standard, :decimal, precision: 10, scale: 2, index: true, comment: "安检津贴标准"
    add_column :allowances, :group_leader_standard, :decimal, precision: 10, scale: 2, index: true, comment: "班组长津贴标准"
    add_column :allowances, :car_present_standard, :decimal, precision: 10, scale: 2, index: true, comment: "车勤补贴标准"
    add_column :allowances, :land_present_standard, :decimal, precision: 10, scale: 2, index: true, comment: "地勤补贴标准"
    add_column :allowances, :permit_entry_standard, :decimal, precision: 10, scale: 2, index: true, comment: "放行补贴标准"
    add_column :allowances, :try_drive_standard, :decimal, precision: 10, scale: 2, index: true, comment: "试车津贴标准"
  end
end

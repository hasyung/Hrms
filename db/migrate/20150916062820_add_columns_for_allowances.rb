class AddColumnsForAllowances < ActiveRecord::Migration
  def change
    add_column :allowances, :security_check, :decimal, precision: 10, scale: 2, index: true, comment: "安检津贴"
    add_column :allowances, :resettlement, :decimal, precision: 10, scale: 2, index: true, comment: "安置津贴"
    add_column :allowances, :group_leader, :decimal, precision: 10, scale: 2, index: true, comment: "班组长津贴"
    add_column :allowances, :air_station_manage, :decimal, precision: 10, scale: 2, index: true, comment: "航站管理津贴"
    add_column :allowances, :car_present, :decimal, precision: 10, scale: 2, index: true, comment: "车勤补贴"
    add_column :allowances, :land_present, :decimal, precision: 10, scale: 2, index: true, comment: "地勤补贴"
    add_column :allowances, :permit_entry, :decimal, precision: 10, scale: 2, index: true, comment: "放行补贴"
    add_column :allowances, :try_drive, :decimal, precision: 10, scale: 2, index: true, comment: "试车津贴"
    add_column :allowances, :fly_honor, :decimal, precision: 10, scale: 2, index: true, comment: "飞行荣誉津贴"
    add_column :allowances, :airline_practice, :decimal, precision: 10, scale: 2, index: true, comment: "航线实习补贴"
    add_column :allowances, :follow_plane, :decimal, precision: 10, scale: 2, index: true, comment: "随机补贴"
    add_column :allowances, :permit_sign, :decimal, precision: 10, scale: 2, index: true, comment: "签派放行补贴"
    add_column :allowances, :work_overtime, :decimal, precision: 10, scale: 2, index: true, comment: "梭班补贴"
    add_column :allowances, :temp, :decimal, precision: 10, scale: 2, index: true, comment: "高温补贴"

    remove_column :allowances, :subsidy
  end
end

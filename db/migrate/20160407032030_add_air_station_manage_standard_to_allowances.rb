class AddAirStationManageStandardToAllowances < ActiveRecord::Migration
  def change
  	add_column :allowances, :air_station_manage_standard, :decimal, precision: 10, scale: 2, index: true, comment: "航站管理津贴标准"
  end
end

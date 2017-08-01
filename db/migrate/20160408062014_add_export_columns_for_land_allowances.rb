class AddExportColumnsForLandAllowances < ActiveRecord::Migration
  def change
  	add_column :land_allowances, :standard, :string, index: true, comment: '地面驻站标准'
  	add_column :land_allowances, :days, :string, index: true, comment: '地面驻站天数'
  	add_column :land_allowances, :locations, :string, index: true, comment: '地面驻站地点'
  end
end

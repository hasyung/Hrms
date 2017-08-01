class AddFieldsToLandAllowances < ActiveRecord::Migration
  def change
    add_column :land_allowances, :short_days, :integer, default: 0, index: true, comment: '当月累计的短期驻站天数'
    add_column :land_allowances, :metaphase_days, :integer, default: 0, index: true, comment: '当月累计的中期驻站天数'
    add_column :land_allowances, :long_days, :integer, default: 0, index: true, comment: '当月累计的长期驻站天数'
    add_column :land_allowances, :short_days_list, :text, comment: '短期驻站日期列表'
    add_column :land_allowances, :metaphase_days_list, :text, comment: '中期驻站日期列表'
    add_column :land_allowances, :long_days_list, :text, comment: '长期驻站日期列表'
    add_column :land_allowances, :food_fee, :decimal, precision: 10, scale: 2, default: 0, index: true, comment: '餐食补助'
    add_column :land_allowances, :cold_fee, :decimal, precision: 10, scale: 2, default: 0, index: true, comment: '高寒补助'

    LandAllowance.update_all(short_days_list: [], metaphase_days_list: [], long_days_list: [])
  end
end

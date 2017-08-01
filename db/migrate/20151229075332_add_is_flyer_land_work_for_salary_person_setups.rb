class AddIsFlyerLandWorkForSalaryPersonSetups < ActiveRecord::Migration
  def change
    add_column :salary_person_setups, :is_flyer_land_work, :boolean, index: true, default: false, comment: '飞行/空勤地面行政班'

    add_column :hours_fees, :is_land_work, :boolean, index: true, default: false, comment: '空勤地面行政班兼职'
    add_column :hours_fees, :land_work_money, :decimal, precision: 10, scale: 2, index: true, comment: '空勤地面行政班兼职金额'
  end
end

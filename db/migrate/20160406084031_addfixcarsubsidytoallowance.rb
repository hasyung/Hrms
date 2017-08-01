class Addfixcarsubsidytoallowance < ActiveRecord::Migration
  def change
    add_column :allowances, :cq_part_time_fix_car_subsidy, :decimal, precision: 10, scale: 2, index: true, comment: '重庆兼职车辆维修班补贴'
    add_column :allowances, :cq_part_time_fix_car_subsidy_standard, :decimal, precision: 10, scale: 2, index: true, comment: '重庆兼职车辆维修班补贴准'

    add_column :salary_person_setups, :cq_part_time_fix_car_subsidy, :string, index: true, comment: '重庆兼职车辆维修班补贴'
  end
end

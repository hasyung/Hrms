class AddKeepFieldsToSalaryPersonSetups < ActiveRecord::Migration
  def change
    add_column :salary_person_setups, :keep_position, :decimal, precision: 10, scale: 2, index: true
    add_column :salary_person_setups, :keep_performance, :decimal, precision: 10, scale: 2, index: true
    add_column :salary_person_setups, :keep_working_years, :decimal, precision: 10, scale: 2, index: true
    add_column :salary_person_setups, :keep_minimum_growth, :decimal, precision: 10, scale: 2, index: true
    add_column :salary_person_setups, :keep_land_allowance, :decimal, precision: 10, scale: 2, index: true
    add_column :salary_person_setups, :keep_life_allowance, :decimal, precision: 10, scale: 2, index: true
    add_column :salary_person_setups, :keep_adjustmen_09, :decimal, precision: 10, scale: 2, index: true
    add_column :salary_person_setups, :keep_bus_14, :decimal, precision: 10, scale: 2, index: true
    add_column :salary_person_setups, :keep_communication_14, :decimal, precision: 10, scale: 2, index: true
  end
end

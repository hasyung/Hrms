class SplitKeepLife < ActiveRecord::Migration
  def change
    rename_column :salary_person_setups, :keep_life_allowance, :keep_life_1
    add_column :salary_person_setups, :keep_life_2, :decimal, precision: 10, scale: 2, default: 0, index: true, comment: '保留工资2'

    rename_column :keep_salaries, :life_allowance, :life_1
    add_column :keep_salaries, :life_2, :decimal, precision: 10, scale: 2, default: 0, index: true, comment: '生活保留2'
  end
end

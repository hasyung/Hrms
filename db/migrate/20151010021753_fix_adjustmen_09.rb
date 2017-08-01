class FixAdjustmen09 < ActiveRecord::Migration
  def change
    rename_column :keep_salaries, :adjustmen_09, :adjustment_09
    rename_column :salary_person_setups, :keep_adjustmen_09, :keep_adjustment_09
  end
end

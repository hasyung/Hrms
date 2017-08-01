class RomoveHoursFeeCategoryForEmployees < ActiveRecord::Migration
  def change
    remove_column :employees, :hours_fee_category
  end
end

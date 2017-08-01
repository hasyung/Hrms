class AddCategoryToPerformances < ActiveRecord::Migration
  def change
    add_column :performances, :category, :string
    add_column :performances, :assess_year, :string
    change_column :performances, :assess_time, :date
  end
end

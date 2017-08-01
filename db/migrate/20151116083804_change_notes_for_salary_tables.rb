class ChangeNotesForSalaryTables < ActiveRecord::Migration
  def change
    change_column :basic_salaries, :notes, :text
    change_column :keep_salaries, :notes, :text
    change_column :performance_salaries, :notes, :text
    change_column :hours_fees, :notes, :text
    change_column :allowances, :notes, :text
    change_column :land_allowances, :notes, :text
    change_column :transport_fees, :notes, :text
    change_column :salary_overviews, :notes, :text
  end
end

class RemoveNationIdAndPracticeDateFromEmployees < ActiveRecord::Migration
  def change
    remove_column :employees, :nation_id, :integer
    remove_column :employees, :practice_date, :date
  end
end

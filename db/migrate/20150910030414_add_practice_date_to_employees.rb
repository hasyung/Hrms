class AddPracticeDateToEmployees < ActiveRecord::Migration
  def change
    add_column :employees, :practice_date, :date, index: true
  end
end

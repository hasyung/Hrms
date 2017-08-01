class AddStartInternShipDateToEmployees < ActiveRecord::Migration
  def change
    add_column :employees, :start_internship_date, :date
  end
end

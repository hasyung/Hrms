class AddGraduationDateToEmployees < ActiveRecord::Migration
  def change
    add_column :employees, :graduate_date, :date, index: true
  end
end

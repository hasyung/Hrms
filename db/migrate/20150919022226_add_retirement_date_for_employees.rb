class AddRetirementDateForEmployees < ActiveRecord::Migration
  def change
    add_column :employees, :retirement_date, :date, index: true, comment: '退休时间'
  end
end

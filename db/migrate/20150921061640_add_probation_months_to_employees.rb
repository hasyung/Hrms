class AddProbationMonthsToEmployees < ActiveRecord::Migration
  def change
    add_column :employees, :probation_months, :string, default: '0'
  end
end

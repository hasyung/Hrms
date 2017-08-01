class AddTimestampsToPerformanceSalary < ActiveRecord::Migration
  def change
    add_column :performance_salaries, :created_at, :datetime
    add_column :performance_salaries, :updated_at, :datetime
  end
end

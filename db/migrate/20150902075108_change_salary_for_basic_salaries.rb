class ChangeSalaryForBasicSalaries < ActiveRecord::Migration
  def change
    remove_column :basic_salaries, :salary
    add_column :basic_salaries, :position_salary, :decimal, precision: 10, scale: 2
    add_column :basic_salaries, :working_years_salary, :decimal, precision: 10, scale: 2
    add_column :basic_salaries, :reserve_salary, :decimal, precision: 10, scale: 2

    change_column :performance_salaries, :base_salary, :decimal, precision: 10, scale: 2
    change_column :performance_salaries, :amount, :decimal, precision: 10, scale: 2
    change_column :performance_salaries, :add_garnishee, :decimal, precision: 10, scale: 2
  end
end

class RemoveReserveSalaryFromBasicSalaries < ActiveRecord::Migration
  def change
    remove_column :basic_salaries, :reserve_salary
  end
end

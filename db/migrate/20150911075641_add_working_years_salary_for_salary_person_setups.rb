class AddWorkingYearsSalaryForSalaryPersonSetups < ActiveRecord::Migration
  def change
    add_column :salary_person_setups, :working_years_salary, :decimal, precision: 10, scale: 2, index: true, comment: "工龄工资"
    change_column :salary_person_setups, :reserve_wage, :decimal, precision: 10, scale: 2, index: true, comment: "保留工资"
  end
end

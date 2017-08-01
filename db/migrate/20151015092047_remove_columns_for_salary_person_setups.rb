class RemoveColumnsForSalaryPersonSetups < ActiveRecord::Migration
  def change
    remove_column :salary_person_setups, :employee_name
    remove_column :salary_person_setups, :employee_no
    remove_column :salary_person_setups, :department_name
    remove_column :salary_person_setups, :position_name
  end
end

class AddEmployeeCategoryToEmployeeWorkExperiences < ActiveRecord::Migration
  def change
    add_column :employee_work_experiences, :employee_category, :string
  end
end

class RemoveJobTitleIdFromEmployees < ActiveRecord::Migration
  def change
    remove_column :employees, :job_title_id, :integer
    drop_table :employee_job_titles
  end
end

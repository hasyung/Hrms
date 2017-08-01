class AddLeaveJobFieldsToEmployees < ActiveRecord::Migration
  def change
  	add_column :employees, :approve_leave_job_date, :date, index: true
  	add_column :employees, :leave_job_reason, :string, index: true
  	add_column :employees, :is_delete, :boolean, default: false, index: true
  end
end

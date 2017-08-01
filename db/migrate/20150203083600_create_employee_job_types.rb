class CreateEmployeeJobTypes < ActiveRecord::Migration
  def change
    create_table :employee_job_types do |t|
    	t.string :name
    	t.string :display_name #展示名字
    end
  end
end

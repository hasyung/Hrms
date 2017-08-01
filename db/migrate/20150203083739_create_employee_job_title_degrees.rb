class CreateEmployeeJobTitleDegrees < ActiveRecord::Migration
  def change
    create_table :employee_job_title_degrees do |t|
    	t.integer :job_type_id
    	t.string    :name
    	t.string :display_name #展示名字
    end
  end
end

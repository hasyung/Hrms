class AddLevelForJobTitleDegrees < ActiveRecord::Migration
  def change
    add_column :employee_job_title_degrees, :level, :integer, index: true
  end
end

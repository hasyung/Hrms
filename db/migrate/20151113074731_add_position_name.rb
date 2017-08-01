class AddPositionName < ActiveRecord::Migration
  def change
    add_column :salary_grade_changes, :position_name, :string
    add_column :salary_grade_changes, :last_transfer_date, :date
    add_column :salary_grade_changes, :fly_total_time, :integer
  end
end

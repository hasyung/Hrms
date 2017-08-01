class AddGroundWorkDaysFromAttendanceSummaries < ActiveRecord::Migration
  def change
    add_column :attendance_summaries, :ground_work_days, :string, default: 0
  end
end

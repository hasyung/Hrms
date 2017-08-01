class AddSurfaceWorkDaysFromAttendanceSummaries < ActiveRecord::Migration
  def change
    add_column :attendance_summaries, :surface_work_days, :string, default: 0
  end
end

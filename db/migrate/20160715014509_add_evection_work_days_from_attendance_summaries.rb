class AddEvectionWorkDaysFromAttendanceSummaries < ActiveRecord::Migration
  def change
    add_column :attendance_summaries, :evection_work_days, :string, default: 0
  end
end

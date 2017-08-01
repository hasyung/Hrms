class AddWorkDaysFromAttendanceSummaries < ActiveRecord::Migration
  def change
    add_column :attendance_summaries, :cultivate_work_days, :string, default: 0, index: true
    add_column :attendance_summaries, :evection_work_days, :string, default: 0, index: true
    add_column :attendance_summaries, :ground_work_days, :string, default: 0, index: true
    add_column :attendance_summaries, :surface_work_days, :string, default: 0, index: true
  end
end

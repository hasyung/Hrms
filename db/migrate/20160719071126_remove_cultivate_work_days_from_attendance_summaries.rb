class RemoveCultivateWorkDaysFromAttendanceSummaries < ActiveRecord::Migration
  def change
    remove_column :attendance_summaries, :cultivate_work_days, :string
    remove_column :attendance_summaries, :evection_work_days, :string
    remove_column :attendance_summaries, :ground_work_days, :string
    remove_column :attendance_summaries, :surface_work_days, :string
  end
end

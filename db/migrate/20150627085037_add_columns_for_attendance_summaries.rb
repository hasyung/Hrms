class AddColumnsForAttendanceSummaries < ActiveRecord::Migration
  def change
    add_column :attendance_summaries, :department_id, :integer, index: true if AttendanceSummary.column_names.exclude?('department_id')
    add_column :attendance_summaries, :attendance_summary_status_manager_id, :integer, index: true if AttendanceSummary.column_names.exclude?('attendance_summary_status_manager_id')
  end
end

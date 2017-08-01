class AddPersonalLeaveWorkDaysAndSickLeaveWorkDaysToAttendanceSummaries < ActiveRecord::Migration
  def change
    add_column :attendance_summaries, :personal_leave_work_days, :string, default: '0', comment: '事假工作日天数'
    add_column :attendance_summaries, :sick_leave_work_days, :string, default: '0', comment: '病假工作日天数' 
  end
end

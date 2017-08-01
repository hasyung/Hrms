class AddHomeLeaveWorkDaysForAttendanceSummaries < ActiveRecord::Migration
  def change
    add_column :attendance_summaries, :home_leave_work_days, :string, default: '0', comment: '探亲假工作日'
  end
end

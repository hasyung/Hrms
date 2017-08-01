class AddPublicLeaveToAttendanceSummaries < ActiveRecord::Migration
  def change
    add_column :attendance_summaries, :public_leave, :string, index: true, default: '0'
  end
end

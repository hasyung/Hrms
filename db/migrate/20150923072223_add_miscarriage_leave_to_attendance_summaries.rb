class AddMiscarriageLeaveToAttendanceSummaries < ActiveRecord::Migration
  def change
    add_column :attendance_summaries, :miscarriage_leave, :string, default: '0' # 流产假
  end
end

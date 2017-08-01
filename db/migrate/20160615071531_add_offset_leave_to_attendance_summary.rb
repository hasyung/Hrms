class AddOffsetLeaveToAttendanceSummary < ActiveRecord::Migration
  def change
    add_column :attendance_summaries, :offset_leave, :string, default: '0', comment: '补休假'
  end
end

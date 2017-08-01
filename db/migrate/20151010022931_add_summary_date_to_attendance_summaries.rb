class AddSummaryDateToAttendanceSummaries < ActiveRecord::Migration
  def change
    add_column :attendance_summaries, :summary_date, :string, index:true
  end
end

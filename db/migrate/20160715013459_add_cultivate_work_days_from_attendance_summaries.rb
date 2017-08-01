class AddCultivateWorkDaysFromAttendanceSummaries < ActiveRecord::Migration
  def change
    add_column :attendance_summaries, :cultivate_work_days, :string, default: 0
  end
end

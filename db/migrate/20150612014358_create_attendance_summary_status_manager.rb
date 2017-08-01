class CreateAttendanceSummaryStatusManager < ActiveRecord::Migration
  def change
    create_table :attendance_summary_status_managers do |t|
      t.boolean :department_hr_checked, default: false
      t.boolean :department_leader_checked, default: false
      t.boolean :hr_department_leader_checked, default: false
      t.string  :summary_date, index: true, null: false
      t.integer :department_id, index: true
      t.string  :department_name

      remove_column :attendance_summaries, :month, :string if AttendanceSummary.column_names.include?('month')

      add_column :attendance_summaries, :department_id, :integer, index: true if AttendanceSummary.column_names.include?('department_id')
      add_column :attendance_summaries, :attendance_summary_status_manager_id, :integer, index: true if AttendanceSummary.column_names.include?('attendance_summary_status_manager_id')

      t.timestamps null: false
    end
  end
end

class AddDetailOperatorsToAttendanceSummaryStatusManagers < ActiveRecord::Migration
  def change
    remove_column :attendance_summary_status_managers, :operator_form, :string

    add_column :attendance_summary_status_managers, :hr_name, :string
    add_column :attendance_summary_status_managers, :hr_confirmed_at, :datetime

    add_column :attendance_summary_status_managers, :department_leader_name, :string
    add_column :attendance_summary_status_managers, :department_leader_confirmed_at, :datetime

    add_column :attendance_summary_status_managers, :hr_leader_name, :string
    add_column :attendance_summary_status_managers, :hr_leader_confirmed_at, :datetime
  end
end

class AddHrLaborRelationMemberColumnToAttendanceSummaryStatusManagers < ActiveRecord::Migration
  def change
    add_column :attendance_summary_status_managers, :hr_labor_relation_member_cheked, :boolean, default: false
    add_column :attendance_summary_status_managers, :hr_labor_relation_member_name, :string
    add_column :attendance_summary_status_managers, :hr_labor_relation_member_confirmed_at, :datetime
    add_column :attendance_summary_status_managers, :hr_labor_relation_member_opinion, :string
  end
end

class AddOperatorFormToAttendanceSummaryStatusManagers < ActiveRecord::Migration
  def change
    add_column :attendance_summary_status_managers, :operator_form, :string
  end
end

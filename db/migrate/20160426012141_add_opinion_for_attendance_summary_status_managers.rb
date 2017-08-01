class AddOpinionForAttendanceSummaryStatusManagers < ActiveRecord::Migration
  def change
  	add_column :attendance_summary_status_managers, :department_leader_opinion, :string, index: true, comment: '部门领导意见'
  	add_column :attendance_summary_status_managers, :hr_department_leader_opinion, :string, index: true, comment: 'HR领导意见'
  end
end

class RenameHrLaborRelationMemberChekedToHrLaborRelationMemberChecked < ActiveRecord::Migration
  def change
    rename_column :attendance_summary_status_managers, :hr_labor_relation_member_cheked, :hr_labor_relation_member_checked
  end
end

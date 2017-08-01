class ChangeSalarySetupIdForSalaryChanges < ActiveRecord::Migration
  def change
    change_column :salary_changes, :salary_person_setup_id, :integer, index: true, null: true
    rename_column :salary_changes, :position_name_was, :position_name_history
  end
end

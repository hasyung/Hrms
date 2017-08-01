class AddReasonForSalaryChanges < ActiveRecord::Migration
  def change
    add_column :salary_changes, :reason, :string, index: true
  end
end

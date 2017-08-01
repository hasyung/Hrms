class AddEmployeeIdForAllegeAttachments < ActiveRecord::Migration
  def change
    add_column :performance_allege_attachments, :employee_id, :integer, null: false, index: true
  end
end

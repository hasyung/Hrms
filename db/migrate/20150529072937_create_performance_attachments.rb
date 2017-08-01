class CreatePerformanceAttachments < ActiveRecord::Migration
  def change
    create_table :performance_attachments do |t|
      t.integer :performance_id, null:false, index: true
      t.integer :employee_id, null:false, index: true

      t.string  :file_name
      t.string  :file_type
      t.integer :file_size,     default: 0

      t.string  :file

      t.timestamps null: false
    end
  end
end

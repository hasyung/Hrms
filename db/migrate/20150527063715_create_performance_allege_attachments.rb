class CreatePerformanceAllegeAttachments < ActiveRecord::Migration
  def change
    create_table :performance_allege_attachments do |t|
      t.integer :performance_allege_id, null: false, index: true

      t.string  :file
      t.string  :file_name
      t.string  :file_type
      t.integer :file_size,     default: 0
      t.timestamps null: false
    end
  end
end

class CreateFlowAttachments < ActiveRecord::Migration
  def change
    create_table :flow_attachments do |t|
      t.integer :flow_id
      t.string  :file
      t.string  :file_type
      t.integer :file_size,     default: 0
      t.timestamps null: false
    end
  end
end

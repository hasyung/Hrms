class ChangeAttachments < ActiveRecord::Migration
  def change
    add_column :attachments, :file_name, :string
    add_column :attachments, :file_type, :string
    add_column :attachments, :file_size, :integer, default: 0
    add_column :attachments, :file, :string
    add_column :attachments, :employee_id, :integer

    remove_column :attachments, :path 
    remove_column :attachments, :size 
    remove_column :attachments, :mimetype
    remove_column :attachments, :user_id

    add_index :attachments, :employee_id
  end
end

class AddFileNameForFlowAttachments < ActiveRecord::Migration
  def change
    add_column :flow_attachments, :file_name, :string
  end
end

class DropTable < ActiveRecord::Migration
  def change
    drop_table :performance_attachments
  end
end

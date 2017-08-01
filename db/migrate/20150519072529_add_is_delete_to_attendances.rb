class AddIsDeleteToAttendances < ActiveRecord::Migration
  def change
    add_column :attendances, :is_delete, :boolean, default: false, index: true
  end
end

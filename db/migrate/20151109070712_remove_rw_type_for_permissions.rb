class RemoveRwTypeForPermissions < ActiveRecord::Migration
  def change
    remove_column :permissions, :rw_type if Permission.column_names.include?('rw_type')
    remove_column :logs, :rw_type if Log.column_names.include?('rw_type')
  end
end

class FixPermissionsBitValueLength < ActiveRecord::Migration
  def change
    begin
      remove_index :permissions, :bit_value
    rescue
    end

    change_column :permissions, :bit_value, :text, default: nil
  end
end

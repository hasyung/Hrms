class FixEmployeesBitValueLength < ActiveRecord::Migration
  def change
    begin
      remove_index :employees, :bit_value
    rescue
    end

    change_column :employees, :bit_value, :text, default: nil
  end
end

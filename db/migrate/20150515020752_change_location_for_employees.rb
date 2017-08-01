class ChangeLocationForEmployees < ActiveRecord::Migration
  def change
    remove_column :employees, :location_id
    add_column    :employees, :location, :string, index: true
  end
end

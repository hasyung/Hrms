class AddClassificationToEmployees < ActiveRecord::Migration
  def change
    add_column :employees, :classification, :string
  end
end

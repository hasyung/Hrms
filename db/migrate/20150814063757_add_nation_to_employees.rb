class AddNationToEmployees < ActiveRecord::Migration
  def change
    add_column :employees, :nation, :string
  end
end

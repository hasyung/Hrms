class AddStarToEmployee < ActiveRecord::Migration
  def change
    add_column :employees, :star, :string
  end
end

class ChangeStarForEmployee < ActiveRecord::Migration
  def change
  	add_index :employees, :star
  end
end

class AddMonthToRewards < ActiveRecord::Migration
  def change
    add_column :rewards, :month, :string, index: true
  end
end

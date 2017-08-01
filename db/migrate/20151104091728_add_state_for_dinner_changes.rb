class AddStateForDinnerChanges < ActiveRecord::Migration
  def change
    add_column :dinner_changes, :state, :string, default: '未处理', index: true
  end
end

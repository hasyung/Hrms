class AddFileNoToSpecialStates < ActiveRecord::Migration
  def change
    add_column :special_states, :file_no, :string, :comment => "文件号"
  end
end

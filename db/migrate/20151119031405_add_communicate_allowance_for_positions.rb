class AddCommunicateAllowanceForPositions < ActiveRecord::Migration
  def change
    add_column :positions, :communicate_allowance, :integer, default: 0, index: true, comment: '通讯补贴'
  end
end

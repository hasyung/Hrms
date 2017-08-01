class ChangeDueTimeInContracts < ActiveRecord::Migration
  def change
    change_column :contracts, :due_time, :string
  end
end

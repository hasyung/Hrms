class AddStopFlyReasonToSpecialStates < ActiveRecord::Migration
  def change
    add_column :special_states, :stop_fly_reason, :string
  end
end

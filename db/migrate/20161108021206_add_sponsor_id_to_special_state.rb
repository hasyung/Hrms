class AddSponsorIdToSpecialState < ActiveRecord::Migration
  def change
  	add_column :special_states, :sponsor_id, :integer, null:true, index: true, comment: "异动发起人ID"
  end
end

class AddParentIdToWorkflowEvents < ActiveRecord::Migration
  def change
  	add_column :workflow_events, :parent_id, :integer, default: 0, index: true
  end
end

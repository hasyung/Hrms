class RemoveColumnsForFlows < ActiveRecord::Migration
  def change
    remove_column :flows, :yaml_workflow_hash
    change_column :flows, :workflow_state, :string, default: 'checking'
    
    remove_column :workflow_events, :event
    remove_column :workflow_events, :parent_id
  end
end

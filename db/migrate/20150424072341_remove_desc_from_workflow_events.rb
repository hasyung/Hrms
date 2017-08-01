class RemoveDescFromWorkflowEvents < ActiveRecord::Migration
  def change
    remove_column :workflow_events, :desc
  end
end

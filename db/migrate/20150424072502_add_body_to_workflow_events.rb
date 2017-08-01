class AddBodyToWorkflowEvents < ActiveRecord::Migration
  def change
    add_column :workflow_events, :body, :string
  end
end

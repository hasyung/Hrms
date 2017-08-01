class AddYamlWorkflowHashToFlows < ActiveRecord::Migration
  def change
  	add_column :flows, :yaml_workflow_hash, :text
  end
end

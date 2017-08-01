class CreateCodeTableWorkflowStates < ActiveRecord::Migration
  def change
    create_table :code_table_workflow_states do |t|
      t.string :display_name
      t.string :name

      t.timestamps null: false
    end
  end
end

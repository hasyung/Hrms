class CreateWorkflowEvent < ActiveRecord::Migration
  def change
    create_table :workflow_events do |t|
      t.string :flow_id
      t.string :workflow_state
      t.integer :reviewer_id
      t.string :reviewer_no
      t.string :reviewer_name
      t.string :reviewer_position
      t.string :reviewer_department
      t.string :desc
      t.string :event #通过或不通过

      t.timestamps null: false
    end
  end
end

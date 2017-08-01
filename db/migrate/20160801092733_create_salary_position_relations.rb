class CreateSalaryPositionRelations < ActiveRecord::Migration
  def change
    create_table :salary_position_relations do |t|
    	t.integer :salary_id, index: true
    	t.string  :position_ids, index: true

      t.timestamps null: false
    end
  end
end

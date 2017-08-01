class CreateEmployeeLaborRelations < ActiveRecord::Migration
  def change
    create_table :employee_labor_relations do |t|
      t.string :name
      t.string :display_name

      t.timestamps null: false
    end
  end
end

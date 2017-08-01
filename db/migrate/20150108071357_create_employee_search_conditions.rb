class CreateEmployeeSearchConditions < ActiveRecord::Migration
  def change
    create_table :employee_search_conditions do |t|
      t.integer    :employee_id,  null: false
      t.string     :name
      t.string     :code
      t.string     :condition
      t.timestamps null: false

      t.index :employee_id
      t.index :code
      t.index :name
    end
  end
end

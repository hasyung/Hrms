class CreateLanguages < ActiveRecord::Migration
  def change
    create_table :languages do |t|
      t.integer :employee_id, index: true
      t.string :name, index: true
      t.string :grade, index: true

      t.timestamps null: false
    end
  end
end

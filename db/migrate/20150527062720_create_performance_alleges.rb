class CreatePerformanceAlleges < ActiveRecord::Migration
  def change
    create_table :performance_alleges do |t|
      t.integer :performance_id, null: false, index: true

      t.string :outcome, index: true
      t.text :reason
      t.timestamps null: false
    end
  end
end

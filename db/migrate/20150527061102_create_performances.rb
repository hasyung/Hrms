class CreatePerformances < ActiveRecord::Migration
  def change
    create_table :performances do |t|
      t.integer :employee_id
      t.string :employee_name
      t.string :employee_no
      t.string :department_name
      t.string :position_name
      t.string :channel
      t.string :assess_time
      t.string :result, default: "无"
      t.integer :sort_no
      t.string :employee_category

      t.timestamps null: false
    end
  end
end

class CreateSalaryGradeChanges < ActiveRecord::Migration
  def change
    create_table :salary_grade_changes do |t|
      t.integer :employee_id, index: true
      t.string :employee_no, index: true
      t.string :employee_name, index: true
      t.string :department_name, index: true
      t.integer :labor_relation_id, index: true
      t.integer :channel_id, index: true
      t.date :record_date
      t.string :change_module
      t.text :form_data
      t.string :result, default: 'checking', index: true

      t.timestamps null: false
    end
  end
end

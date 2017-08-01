class CreateSalaryChanges < ActiveRecord::Migration
  def change
    create_table :salary_changes do |t|
      t.integer :employee_id, null: false, index: true
      t.integer :salary_person_setup_id, null: false, index: true

      t.string  :employee_name, index: true
      t.string  :employee_no, index: true
      t.string  :department_name, index: true
      t.string  :position_name, index: true

      t.string  :category, index: true
      t.string  :state, default: '未处理', index: true
      t.date    :change_date, index: true

      t.string  :position_name_was, index: true

      t.timestamps null: false
    end
  end
end

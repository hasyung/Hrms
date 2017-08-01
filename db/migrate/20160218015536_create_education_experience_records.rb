class CreateEducationExperienceRecords < ActiveRecord::Migration
  def change
    create_table :education_experience_records do |t|
      t.integer :employee_id, index: true
      t.string  :employee_name, index: true
      t.string  :employee_no, index: true
      t.string  :department_name, index: true

      t.string  :school
      t.string  :major
      t.integer :education_background_id, index: true
      t.integer :degree_id, index: true
      t.date    :graduation_date, index: true
      t.date    :change_date, index: true

      t.timestamps null: false
    end
  end
end

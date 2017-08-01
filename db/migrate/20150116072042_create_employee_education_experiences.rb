class CreateEmployeeEducationExperiences < ActiveRecord::Migration
  def change
    create_table :employee_education_experiences do |t|
      t.string :school #学校
      t.string :major #专业
      t.string :admission_date #入学时间
      t.string :graduation_date #毕业时间
      t.integer :education_background_id #学历
      t.integer :education_nature_id #教育性质
      t.integer :degree_id #学位
      t.string :witness #证明人
      t.string :category, default: 'before' #川航前后分类

      t.integer :employee_id

      t.timestamps null: false
    end
  end
end

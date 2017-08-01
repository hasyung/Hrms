class CreateEmployeeWorkExperiences < ActiveRecord::Migration
  def change
    create_table :employee_work_experiences do |t|
      t.string :company #公司
      t.string :department #部门
      t.string :position #岗位
      t.string :job_desc #工作内容
      t.string :job_title #职务
      t.string :start_date #开始时间
      t.string :end_date #结束时间
      t.string :witness #证明人
      t.string :category, default: 'before' #川航前后分类

      t.integer :employee_id

      t.timestamps null: false
    end
  end
end

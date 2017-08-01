class CreateDepartmentChangeLogs < ActiveRecord::Migration
  def change
    create_table :department_change_logs do |t|
      t.string :title #标题
      t.string :oa_file_no  #oa文件号
      t.text :step_desc #步骤描述
      t.string :dep_name  #对应机构名称
      t.integer :department_id  #对应机构

      t.timestamps null: false
    end
  end
end

class CreateCodeTableDepartmentGrades < ActiveRecord::Migration
  def change
    create_table :code_table_department_grades do |t|
      t.string  :name   #名称
      t.integer :level  #层级
      t.integer :index  #标记
      t.integer :readable_index #可读标记
      t.string  :display_name #展示名字

      t.timestamps null: false

      t.index :name
    end
  end
end

class CreateAction < ActiveRecord::Migration
  def change
    create_table :actions do |t|
      t.string :model #模型
      t.string :category  #操作类型
      t.string :description #描述
      t.text :data  #数据
      t.integer :employee_id  #操作员工

      t.index :model
      t.index :category

      t.timestamps null: false
    end
  end
end

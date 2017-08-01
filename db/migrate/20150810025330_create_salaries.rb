class CreateSalaries < ActiveRecord::Migration
  def change
    create_table :salaries do |t|
      t.string :category, index: true, unique: true #类型（全局设置："global"）
      t.string :table_type, index: true, unique: true #表格类型（静态："static", 动态: "dynamic"）
      t.text   :form_data #hash

      t.timestamps null: false
    end
  end
end

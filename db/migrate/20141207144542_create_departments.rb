class CreateDepartments < ActiveRecord::Migration
  def change
    create_table :departments do |t|
      t.string :name #机构名
      t.string :pinyin_name
      t.string :pinyin_index
      t.string :serial_number #机构编码
      t.integer :depth  #深度
      t.integer :childrens_count, default: 0  #子机构树
      t.integer :grade_id, default: 0 #职称级别
      t.integer :nature_id  #机构性质(山产机构／机关机构／分基地机构)
      t.integer :parent_id  #父节点
      t.integer :childrens_index, default: 0 #记录当前子机构serial_number最大值

      t.timestamps null: false
    end
  end
end

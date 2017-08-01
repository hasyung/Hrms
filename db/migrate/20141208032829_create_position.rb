class CreatePosition < ActiveRecord::Migration
  def change
    create_table :positions do |t|
      t.string :pinyin_name
      t.string :pinyin_index
      t.string :name  #岗位名称
      t.integer :budgeted_staffing #编制
      t.string :oa_file_no  #oa文件号
      t.string :post_type #岗位类别
      t.string :remark #备注

      t.integer :department_id  #所在机构
      t.integer :channel_id #通道
      t.integer :schedule_id  #工作时间制
      t.integer :category_id  #分类
      t.integer :position_nature_id #岗位性质
      t.integer :employees_count, default: 0  #在岗人数
      t.string   :flow_bit_value, default: '0'

      t.index :flow_bit_value  #流程权限值

      t.timestamps null: false
    end
  end
end

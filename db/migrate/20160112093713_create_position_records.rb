class CreatePositionRecords < ActiveRecord::Migration
  def change
    create_table :position_records do |t|
      t.integer :employee_id,       index: true, comment: '员工ID'
      t.string  :employee_name,     index: true, comment: '员工姓名'
      t.string  :employee_no,       index: true, comment: '员工编号'
      t.integer :labor_relation_id, index: true, comment: '用工性质'
      t.date    :change_date,       index: true, comment: '岗位变动日期'

      t.string :pre_department_name, comment: '原部门'
      t.string :pre_position_name,   comment: '原岗位'
      t.string :pre_category_name,   comment: '原分类'
      t.string :pre_channel_name,    comment: '原通道'
      t.string :pre_location,        comment: '原属地'
      t.string :pre_duty_rank_name,  comment: '原职务职级'
      t.string :pre_classification,  comment: '原类别'

      t.string :department_name, comment: '现部门'
      t.string :position_name,   comment: '现岗位'
      t.string :category_name,   comment: '现分类'
      t.string :channel_name,    comment: '现通道'
      t.string :location,        comment: '现属地'
      t.string :duty_rank_name,  comment: '现职务职级'
      t.string :classification,  comment: '现类别'

      t.string :oa_file_no, comment: '文件号'
      t.string :note, comment: '备注'

      t.timestamps null: false
    end
  end
end

class CreateTitleInfoChangeRecords < ActiveRecord::Migration
  def change
    create_table :title_info_change_records do |t|
      t.integer :employee_id, index: true, null: false, comment: "人员ID"
      t.string :prev_job_title, index: true, null: true, default: nil, comment: "原职称"
      t.integer :prev_job_title_degree_id, index: true, null: true, default: nil, comment: "原职称级别ID"
      t.string :prev_technical_duty, index: true, null: true, default: nil, comment: "原技术职务"
      t.string :prev_file_no, index: true, null: true, default: nil, comment: "原文件号"
      t.string :job_title, index: true, null: true, default: nil, comment: "职称"
      t.integer :job_title_degree_id, index: true, null: true, default: nil, comment: "职称级别ID"
      t.string :technical_duty, index: true, null: true, default: nil, comment: "技术职务"
      t.string :file_no, index: true, null: true, default: nil, comment: "文件号"
      t.date   :change_date, index: true, null: true, default: nil, comment: "修改时间"

      t.timestamps null: false
    end
  end
end

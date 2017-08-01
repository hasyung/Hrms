class CreateTechnicalGradeChangeRecords < ActiveRecord::Migration
  def change
    create_table :technical_grade_change_records do |t|
      t.integer :employee_id, index: true, comment: '员工ID'
      t.string  :technical_grade, comment: '变更的技术通道'
      t.date    :change_date, comment: '变更日期'
      t.string  :oa_file_no, comment: '文件号'
      t.boolean :status, default: false, index: true, comment: '状态码'

      t.timestamps null: false
    end
  end
end

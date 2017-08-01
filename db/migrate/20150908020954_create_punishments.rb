class CreatePunishments < ActiveRecord::Migration
  def change
    create_table :punishments do |t|
      t.integer :employee_id, null: false, index: true

      t.string  :employee_name, index: true, comment: "姓名"
      t.string  :category, index: true, comment: "处分类别"
      t.text    :desc, comment: "处分描述"
      t.date    :start_date, index: true, comment: "开始日期"
      t.date    :end_date, index: true, comment: "结束日期"

      t.timestamps null: false
    end
  end
end

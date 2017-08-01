class CreateFlyerInfos < ActiveRecord::Migration
  def change
    create_table :flyer_infos do |t|
      t.integer :employee_id, index: true, comment: '员工id'

      t.decimal :total_fly_time, precision: 10, scale: 2, default: 0, index: true, comment: '飞行员总飞行时间'
      t.date :copilot_date, index: true, comment: '飞行员副驾驶取得时间'
      t.date :teacher_A_date, index: true, comment: '飞行A类教员取得时间'
      t.date :teacher_B_date, index: true, comment: '飞行B类教员取得时间'
      t.date :teacher_C_date, index: true, comment: '飞行C类教员取得时间'

      t.timestamps null: false
    end
  end
end

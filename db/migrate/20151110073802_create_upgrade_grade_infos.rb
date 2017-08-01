class CreateUpgradeGradeInfos < ActiveRecord::Migration
  def change
    create_table :upgrade_grade_infos do |t|
      t.integer :employee_id, index: true, comment: '员工ID'

      t.date :last_up_date, index: true, null: false, comment: '上一次调档日期'

      t.timestamps null: false
    end
  end
end

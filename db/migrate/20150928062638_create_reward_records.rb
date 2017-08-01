class CreateRewardRecords < ActiveRecord::Migration
  def change
    create_table :reward_records do |t|
      t.string :employee_name, index: true, comment: '员工姓名'
      t.string :employee_no, index: true, comment: '员工编号'
      t.string :month, index: true, comment: '发放月份'
      t.timestamps null: false
    end
  end
end

class CreateWorkShifts < ActiveRecord::Migration
  def change
    create_table :work_shifts do |t|
      t.integer :employee_id, null: false, index: true, comment: "员工ID"
      t.string :employee_no, null: false, index: true, comment: "员工编号"
      t.string :work_shifts, null: false, index: true, comment: "班制"
      t.date :start_time, null: false, index: true, comment: "班制开始时间"
      t.date :end_time, index: true, comment: "班制结束时间"

      t.timestamps null: false
    end
  end
end

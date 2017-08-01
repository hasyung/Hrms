class CreateAttendanceSummaries < ActiveRecord::Migration
  def change
    create_table :attendance_summaries do |t|
      t.integer :employee_id, null: false, index: true
      t.string :department_name, index: true
      t.string :employee_no, index: true
      t.string :employee_name, index: true
      t.string :labor_relation, index: true #用工性质
      t.integer :paid_leave, index: true #带薪
      t.integer :sick_leave, index: true #病假
      t.integer :sick_leave_injury, index: true #病假(工伤待定)
      t.integer :sick_leave_nulliparous, index: true #病假(怀孕待产
      t.integer :personal_leave, index: true #事假
      t.integer :home_leave, index: true #探亲假
      t.integer :cultivate, index: true #培训
      t.integer :evection, index: true #出差
      t.integer :absenteeism, index: true #旷工
      t.integer :late_or_leave, index: true #迟到早退
      t.integer :ground, index: true #空勤停飞
      t.integer :surface_work, index: true #空勤地面工作
      t.integer :station_days, index: true #驻站天数
      t.string :station_place, index: true #驻站地点
      t.string :remark, index: true #备注
      t.string :month, null: false, index: true #考勤月

      t.timestamps null: false
    end
  end
end

class AddLeaveFlyerStudentDate < ActiveRecord::Migration
  def change
    add_column :employees, :leave_flyer_student_date, :date, index: true, comment: '飞行学员下队的时间'
  end
end

class ChangeFlyerStudentTrain < ActiveRecord::Migration
  def change
  	remove_column :salary_person_setups, :flyer_student_train
  	add_column :salary_person_setups, :flyer_student_train, :boolean, default: false, index: true, comment: '飞行学员训练'
  end
end

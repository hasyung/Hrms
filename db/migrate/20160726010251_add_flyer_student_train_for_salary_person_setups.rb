class AddFlyerStudentTrainForSalaryPersonSetups < ActiveRecord::Migration
  def change
  	add_column :salary_person_setups, :flyer_student_train, :boolean, default: true, index: true, comment: '飞行学员训练'
  end
end

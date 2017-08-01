class AddDemoFlyMoneyForHoursFees < ActiveRecord::Migration
  def change
  	add_column :hours_fees, :demo_fly_money, :decimal, precision: 10, scale: 2, index: true, comment: "模拟机金额"

  	change_column :salary_person_setups, :flyer_student_train, :boolean, default: false, index: true, comment: '飞行学员训练'
  end
end

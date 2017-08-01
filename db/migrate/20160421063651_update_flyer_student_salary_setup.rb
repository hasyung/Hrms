class UpdateFlyerStudentSalarySetup < ActiveRecord::Migration
  def change
  	dep = Department.find_by(name:'飞行学员队')
  	pos = dep.positions.find_by(name:'飞行员') if dep
  	pos.employees.each do |employee|
  		if employee.salary_person_setup.blank?
	  		setup = employee.build_salary_person_setup
	  		setup.update(fly_hour_fee: 'student', fly_hour_money: 0)
	  	end
  	end if pos
  end
end

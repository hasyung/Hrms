class ChangeGradeForAnyDepartments < ActiveRecord::Migration
  def change
  	grade = CodeTable::DepartmentGrade.find_by(display_name: '一副级')
  	Department.where("name in (?)", %w(北京运行基地 三亚运行基地 杭州运行基地 哈尔滨运行基地 西安运行基地 绵阳运行基地)).update_all(grade_id: grade.id)
  end
end

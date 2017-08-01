class InsertCodeTableDepartmentGradeValue < ActiveRecord::Migration
  def change
       departmentGade =	CodeTable::DepartmentGrade.where(:readable_index =>32).first
    	 return unless departmentGade.blank? 
    	 departmentGade = CodeTable::DepartmentGrade.new
    	 departmentGade.index = 1
    	 departmentGade.level = 1
    	departmentGade.readable_index = 32
    	departmentGade.display_name = '无'

    	departmentGade.save
  end
end

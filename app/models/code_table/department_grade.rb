# == Schema Information
#
# Table name: code_table_department_grades
#
#  id             :integer          not null, primary key
#  name           :string(255)
#  level          :integer
#  index          :integer
#  readable_index :integer
#  display_name   :string(255)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_code_table_department_grades_on_name  (name)
#

class CodeTable::DepartmentGrade < ActiveRecord::Base
  include Snapshotable

  has_many :departments
end

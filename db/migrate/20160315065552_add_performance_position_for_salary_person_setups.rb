class AddPerformancePositionForSalaryPersonSetups < ActiveRecord::Migration
  def change
  	add_column :salary_person_setups, :performance_position, :string, index: true, comment: '绩效岗位'
  end
end

class InitSalaryPositionRelations < ActiveRecord::Migration
  def change
  	salaries = Salary.where("category like 'service_b%' and category like '%_base'")
  	salaries.each{|salary| SalaryPositionRelation.find_or_create_by(salary_id: salary.id)} unless salaries.empty?
  end
end

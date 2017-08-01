class AddSecurityFeeForSalaryOverviews < ActiveRecord::Migration
  def change
  	add_column :birth_salaries, :security_fee, :decimal, precision: 10, scale: 2, default: 0, index: true, comment: '安飞奖'
  	add_column :salary_overviews, :security_fee, :decimal, precision: 10, scale: 2, default: 0, index: true, comment: '安飞奖'
  end
end

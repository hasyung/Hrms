class AddOfficialCarAllowanceForEmployeeDuthRank < ActiveRecord::Migration
  def change
    add_column :employee_duty_ranks, :official_car_allowance, :decimal, precision: 10, scale: 2, default: 0, index: true, comment: '公务车补贴'
  end
end

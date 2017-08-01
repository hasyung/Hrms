class AddCommunicateAllowanceForEmployeeDutyRank < ActiveRecord::Migration
  def change
    add_column :employee_duty_ranks, :communicate_allowance, :decimal, precision: 10, scale: 2, default: 0, index: true, comment: '通讯补贴'
  end
end

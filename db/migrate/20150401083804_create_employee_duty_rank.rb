class CreateEmployeeDutyRank < ActiveRecord::Migration
  def change
    create_table :employee_duty_ranks do |t|
      t.string :name
      t.string :display_name
    end
  end
end

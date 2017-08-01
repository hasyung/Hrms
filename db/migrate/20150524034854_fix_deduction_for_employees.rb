class FixDeductionForEmployees < ActiveRecord::Migration
  def change
  	remove_column :employees, :is_deduction_leave

  	create_table :vacation_violations do |t|
      t.references :employee, index: true
      t.string :category, index: true # 病假违规，事假违规
      t.timestamps null: false
    end
  end
end

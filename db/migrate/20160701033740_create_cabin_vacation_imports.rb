class CreateCabinVacationImports < ActiveRecord::Migration
  def change
    create_table :cabin_vacation_imports do |t|
      t.string :employee_name
      t.string :employee_no
      t.integer :employee_id
      t.boolean :is_checking
      t.integer :sponsor_id
      t.integer :vacation_days
      t.string :leave_type
      t.string :end_leave_date
      t.string :start_leave_date
      t.string :vacation_dates

      t.timestamps null: false
    end
  end
end

class CreateDinnerSettles < ActiveRecord::Migration
  def change
    create_table :dinner_settles do |t|
      t.integer :employee_id, index: true
      t.string :employee_no, index: true
      t.string :employee_name, index: true
      t.string :area, index: true
      t.string :shifts_type, index: true
      t.timestamps null: false
    end
  end
end

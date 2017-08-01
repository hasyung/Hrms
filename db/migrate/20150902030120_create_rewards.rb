class CreateRewards < ActiveRecord::Migration
  def change
    create_table :rewards do |t|
      t.string :department_name
      t.string :position_name

      t.string :employee_name, index: true
      t.string :employee_no, index: true
      t.integer :employee_id, index: true

      t.decimal :flight_bonus, precision: 10, scal: 2, default: 0, index: true
      t.decimal :service_bonus, precision: 10, scal: 2, default: 0, index: true
      t.decimal :ailine_security_bonus, precision: 10, scal: 2, default: 0, index: true
      t.decimal :composite_bonus, precision: 10, scal: 2, default: 0, index: true
      t.decimal :in_out_bonus, precision: 10, scal: 2, default: 0, index: true
      t.decimal :bonus_1, precision: 10, scal: 2, default: 0, index: true
      t.decimal :bonus_2, precision: 10, scal: 2, default: 0, index: true

      t.timestamps
    end
  end
end

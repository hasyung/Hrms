class CreateEmployeePermissions < ActiveRecord::Migration
  def change
    create_table :employee_permissions do |t|
      t.string :bit_value, default: '0'
      t.time :expire_time
      t.integer :employee_id

      t.index :bit_value
      t.index :expire_time

      t.timestamps null: false
    end
  end
end

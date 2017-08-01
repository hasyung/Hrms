class CreateAnnuityApplies < ActiveRecord::Migration
  def change
    create_table :annuity_applies do |t|
      t.integer :employee_id
      t.string  :employee_name
      t.string  :employee_no
      t.string  :department_name
      t.string  :apply_category
      t.boolean :status, default: false, index: true

      t.timestamps null: false
    end
  end
end

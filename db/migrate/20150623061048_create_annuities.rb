class CreateAnnuities < ActiveRecord::Migration
  def change
    create_table :annuities do |t|
      t.integer :employee_id, index: true
      t.string  :cal_date, index: true
      t.string  :employee_no
      t.string  :employee_name, index: true
      t.string  :employee_identity_name, index: true
      t.string  :department_name
      t.string  :position_name
      t.string  :mobile
      t.string  :identity_no
      t.string  :annuity_account_no

      t.decimal  :annuity_cardinality, precision: 10, scale: 2
      t.decimal  :personal_payment, precision: 10, scale: 2
      t.decimal  :company_payment, precision: 10, scale: 2
      t.string   :note

      t.timestamps null: false
    end
  end
end

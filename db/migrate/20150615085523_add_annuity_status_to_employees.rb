class AddAnnuityStatusToEmployees < ActiveRecord::Migration
  def change
    add_column :employees, :annuity_cardinality, :decimal, precision: 10, scale: 2, default: 0
    add_column :employees, :annuity_status, :boolean, default: false
    add_column :employees, :annuity_account_no, :string
    add_column :employees, :identity_name, :string

    add_index :employees, :annuity_cardinality
    add_index :employees, :annuity_status
    add_index :employees, :annuity_account_no
    add_index :employees, :identity_name
  end
end

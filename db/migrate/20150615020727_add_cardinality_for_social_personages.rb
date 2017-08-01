class AddCardinalityForSocialPersonages < ActiveRecord::Migration
  def change
    add_column :social_personages, :cardinality, :integer, index: true
    add_column :social_personages, :social_account, :string, index: true

    add_index :social_personages, :social_location
    add_index :social_personages, :employee_no
    add_index :social_personages, :employee_name
    add_index :social_personages, :department_name
    add_index :social_personages, :position_name

    add_index :social_cardinalities, :social_account
    add_index :social_cardinalities, :employee_no
    add_index :social_cardinalities, :employee_name
    add_index :social_cardinalities, :department_name
    add_index :social_cardinalities, :position_name
    add_index :social_cardinalities, :total
    add_index :social_cardinalities, :cardinality
    add_index :social_cardinalities, :import_month
  end
end

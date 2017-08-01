class AddCardinalitiesForSocial < ActiveRecord::Migration
  def change
    remove_column :social_personages, :cardinality
    remove_column :social_personages, :other_cardinality
    remove_column :social_personages, :temp_cardinality
    add_column :social_personages, :temp_cardinality, :integer, index: true
    add_column :social_personages, :pension_cardinality, :integer, index: true
    add_column :social_personages, :treatment_cardinality, :integer, index: true
    add_column :social_personages, :unemploy_cardinality, :integer, index: true
    add_column :social_personages, :injury_cardinality, :integer, index: true
    add_column :social_personages, :illness_cardinality, :integer, index: true
    add_column :social_personages, :fertility_cardinality, :integer, index: true

    remove_column :social_cardinalities, :cardinality
    remove_column :social_cardinalities, :other_cardinality
    add_column :social_cardinalities, :pension_cardinality, :integer, index: true
    add_column :social_cardinalities, :treatment_cardinality, :integer, index: true
    add_column :social_cardinalities, :unemploy_cardinality, :integer, index: true
    add_column :social_cardinalities, :injury_cardinality, :integer, index: true
    add_column :social_cardinalities, :illness_cardinality, :integer, index: true
    add_column :social_cardinalities, :fertility_cardinality, :integer, index: true
  end
end

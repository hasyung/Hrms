class RollbackCardinalityTypes < ActiveRecord::Migration
  def change
    change_column :social_personages, :cardinality, :integer, index: true
    change_column :social_personages, :other_cardinality, :integer, index: true
    change_column :social_personages, :temp_cardinality, :integer, index: true
    change_column :social_cardinalities, :cardinality, :integer, index: true
    change_column :social_cardinalities, :other_cardinality, :integer, index: true

    remove_column :social_personages, :temp_count
  end
end

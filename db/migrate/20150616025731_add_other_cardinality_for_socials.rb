class AddOtherCardinalityForSocials < ActiveRecord::Migration
  def change
    add_column :social_personages, :other_cardinality, :integer, index: true
    add_column :social_personages, :temp_cardinality, :integer, index: true
    add_column :social_personages, :temp_count, :integer, default: 0, index: true

    add_column :social_cardinalities, :other_cardinality, :integer, index: true
  end
end

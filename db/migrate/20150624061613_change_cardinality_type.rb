class ChangeCardinalityType < ActiveRecord::Migration
  def change
    add_column :social_logs, :change_date, :date
    add_column :social_logs, :salary_reason, :string

    change_column :social_personages, :cardinality, :float, index: true
    change_column :social_personages, :other_cardinality, :float, index: true
    change_column :social_personages, :temp_cardinality, :float, index: true
    change_column :social_cardinalities, :cardinality, :float, index: true
    change_column :social_cardinalities, :other_cardinality, :float, index: true
  end
end

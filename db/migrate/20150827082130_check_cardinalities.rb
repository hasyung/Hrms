class CheckCardinalities < ActiveRecord::Migration
  def change
    change_column :social_cardinalities, :total, :decimal, precision: 10, scale: 2
    change_column :social_cardinalities, :pension_cardinality, :decimal, precision: 10, scale: 2
    change_column :social_cardinalities, :treatment_cardinality, :decimal, precision: 10, scale: 2
    change_column :social_cardinalities, :unemploy_cardinality, :decimal, precision: 10, scale: 2
    change_column :social_cardinalities, :injury_cardinality, :decimal, precision: 10, scale: 2
    change_column :social_cardinalities, :illness_cardinality, :decimal, precision: 10, scale: 2
    change_column :social_cardinalities, :fertility_cardinality, :decimal, precision: 10, scale: 2

    change_column :social_person_setups, :temp_cardinality, :decimal, precision: 10, scale: 2
    change_column :social_person_setups, :pension_cardinality, :decimal, precision: 10, scale: 2
    change_column :social_person_setups, :treatment_cardinality, :decimal, precision: 10, scale: 2
    change_column :social_person_setups, :unemploy_cardinality, :decimal, precision: 10, scale: 2
    change_column :social_person_setups, :injury_cardinality, :decimal, precision: 10, scale: 2
    change_column :social_person_setups, :illness_cardinality, :decimal, precision: 10, scale: 2
    change_column :social_person_setups, :fertility_cardinality, :decimal, precision: 10, scale: 2

    change_column :social_records, :pension_cardinality, :decimal, precision: 10, scale: 2
    change_column :social_records, :other_cardinality, :decimal, precision: 10, scale: 2
    change_column :social_records, :t_company, :decimal, precision: 10, scale: 2
    change_column :social_records, :t_personage, :decimal, precision: 10, scale: 2
    change_column :social_records, :pension_company_scale, :decimal, precision: 10, scale: 2
    change_column :social_records, :pension_personage_scale, :decimal, precision: 10, scale: 2
    change_column :social_records, :pension_company_money, :decimal, precision: 10, scale: 2
    change_column :social_records, :pension_personage_money, :decimal, precision: 10, scale: 2
    change_column :social_records, :treatment_company_scale, :decimal, precision: 10, scale: 2
    change_column :social_records, :treatment_personage_scale, :decimal, precision: 10, scale: 2
    change_column :social_records, :treatment_company_money, :decimal, precision: 10, scale: 2
    change_column :social_records, :treatment_personage_money, :decimal, precision: 10, scale: 2
    change_column :social_records, :unemploy_company_scale, :decimal, precision: 10, scale: 2
    change_column :social_records, :unemploy_personage_scale, :decimal, precision: 10, scale: 2
    change_column :social_records, :unemploy_company_money, :decimal, precision: 10, scale: 2
    change_column :social_records, :unemploy_personage_money, :decimal, precision: 10, scale: 2
    change_column :social_records, :injury_company_scale, :decimal, precision: 10, scale: 2
    change_column :social_records, :injury_personage_scale, :decimal, precision: 10, scale: 2
    change_column :social_records, :injury_company_money, :decimal, precision: 10, scale: 2
    change_column :social_records, :injury_personage_money, :decimal, precision: 10, scale: 2
    change_column :social_records, :illness_company_scale, :decimal, precision: 10, scale: 2
    change_column :social_records, :illness_personage_scale, :decimal, precision: 10, scale: 2
    change_column :social_records, :illness_company_money, :decimal, precision: 10, scale: 2
    change_column :social_records, :illness_personage_money, :decimal, precision: 10, scale: 2
    change_column :social_records, :fertility_company_scale, :decimal, precision: 10, scale: 2
    change_column :social_records, :fertility_personage_scale, :decimal, precision: 10, scale: 2
    change_column :social_records, :fertility_company_money, :decimal, precision: 10, scale: 2
    change_column :social_records, :fertility_personage_money, :decimal, precision: 10, scale: 2
  end
end

class CreateSocialRecords < ActiveRecord::Migration
  def change
    create_table :social_records do |t|
      t.integer :employee_id, null: false, index: true

      t.string  :compute_month, index: true
      t.date    :compute_date, index: true

      t.string  :employee_name, index: true
      t.string  :employee_no, index: true
      t.string  :department_name, index: true
      t.string  :identity_no, index: true
      t.string  :social_account, index: true
      t.string  :social_location, index: true

      t.float   :total, index: true
      t.float   :total_company, index: true
      t.float   :total_personage, index: true
      t.float   :t_company, index: true
      t.float   :t_personage, index: true

      t.integer :pension_cardinality, index: true
      t.integer :other_cardinality, index: true

      t.float   :pension_company_scale, index: true
      t.float   :pension_personage_scale, index: true
      t.float   :pension_company_money, index: true
      t.float   :pension_personage_money, index: true

      t.float   :treatment_company_scale, index: true
      t.float   :treatment_personage_scale, index: true
      t.float   :treatment_company_money, index: true
      t.float   :treatment_personage_money, index: true

      t.float   :unemploy_company_scale, index: true
      t.float   :unemploy_personage_scale, index: true
      t.float   :unemploy_company_money, index: true
      t.float   :unemploy_personage_money, index: true

      t.float   :injury_company_scale, index: true
      t.float   :injury_personage_scale, index: true
      t.float   :injury_company_money, index: true
      t.float   :injury_personage_money, index: true

      t.float   :illness_company_scale, index: true
      t.float   :illness_personage_scale, index: true
      t.float   :illness_company_money, index: true
      t.float   :illness_personage_money, index: true

      t.float   :fertility_company_scale, index: true
      t.float   :fertility_personage_scale, index: true
      t.float   :fertility_company_money, index: true
      t.float   :fertility_personage_money, index: true

      t.string  :remark


      t.timestamps null: false
    end

    add_column :social_cardinalities, :import_date, :date, index: true
    add_column :social_personages, :is_delete, :boolean, default: false, index: true
  end
end

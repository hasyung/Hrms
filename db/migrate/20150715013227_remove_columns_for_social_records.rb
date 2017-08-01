class RemoveColumnsForSocialRecords < ActiveRecord::Migration
  def change
    remove_column :social_records, :total
    remove_column :social_records, :total_company
    remove_column :social_records, :total_personage

    rename_table :social_personages, :social_person_setups
    rename_table :social_logs, :social_change_infos
  end
end

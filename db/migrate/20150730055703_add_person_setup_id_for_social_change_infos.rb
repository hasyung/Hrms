class AddPersonSetupIdForSocialChangeInfos < ActiveRecord::Migration
  def change
    add_column :social_change_infos, :social_person_setup_id, :integer, index: true
  end
end

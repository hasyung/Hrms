class CreatePermissionGroups < ActiveRecord::Migration
  def change
    create_table :permission_groups do |t|
      t.string :name
      t.text   :permission_ids

      t.timestamps null: false
    end
  end
end

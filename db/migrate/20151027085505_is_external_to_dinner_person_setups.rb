class IsExternalToDinnerPersonSetups < ActiveRecord::Migration
  def change
    add_column :dinner_person_setups, :is_external, :boolean, default: false, index: true, comment: '是否外部卡'
  end
end

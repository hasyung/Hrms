class FixFieldTypeForDinnerPersonSetups < ActiveRecord::Migration
  def change
    remove_column :dinner_person_setups, :card_number
    add_column :dinner_person_setups, :card_number, :integer, index: true, comment: '卡次数'
  end
end

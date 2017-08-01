class AddDeficitAmountForDinnerPersonSetups < ActiveRecord::Migration
  def change
    add_column :dinner_person_setups, :deficit_amount, :decimal, precision: 10, scale: 2, index: true, comment: '欠费金额'
  end
end

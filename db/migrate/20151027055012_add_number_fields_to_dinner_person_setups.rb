class AddNumberFieldsToDinnerPersonSetups < ActiveRecord::Migration
  def change
    rename_column :dinner_person_setups, :chengduArea, :area
    rename_column :dinner_person_setups, :cardAmount, :card_amount
    rename_column :dinner_person_setups, :cardNumber, :card_number
    rename_column :dinner_person_setups, :dinnerfee, :working_fee
    add_column :dinner_person_setups, :breakfast_number, :integer, index: true, comment: '早餐次数'
    add_column :dinner_person_setups, :lunch_number, :integer, index: true, comment: '午餐次数'
    add_column :dinner_person_setups, :dinner_number, :integer, index: true, comment: '晚餐次数'
    add_column :dinner_person_setups, :change_date, :date, index: true, comment: '变动日期'
  end
end

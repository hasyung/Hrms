class AddIsSuspendToDinnerPersonSetups < ActiveRecord::Migration
  def change
    add_column :dinner_person_setups, :is_suspend, :boolean, default: false, index: true, comment: '暂停发放餐费标记'
  end
end

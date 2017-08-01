class AddStopPromotionToSalaryPersonSetup < ActiveRecord::Migration
  def change
    add_column :salary_person_setups, :stop_promotion, :boolean, default: false, index: true
  end
end

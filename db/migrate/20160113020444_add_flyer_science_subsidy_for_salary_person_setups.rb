class AddFlyerScienceSubsidyForSalaryPersonSetups < ActiveRecord::Migration
  def change
    add_column :salary_person_setups, :flyer_science_subsidy, :string, index: true, comment: "飞行驾驶技术津贴"
    add_column :salary_person_setups, :flyer_science_money, :decimal, precision: 10, scale: 2, index: true, comment: "飞行驾驶技术津贴金额"
  end
end

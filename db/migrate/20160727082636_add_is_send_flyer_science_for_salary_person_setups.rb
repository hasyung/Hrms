class AddIsSendFlyerScienceForSalaryPersonSetups < ActiveRecord::Migration
  def change
  	add_column :salary_person_setups, :is_send_flyer_science, :boolean, default: false, index: true, comment: '是否发放飞行驾驶技术津贴'
  end
end

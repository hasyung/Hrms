class ChangeIsSendFeesDefaultValue < ActiveRecord::Migration
  def change
  	remove_column :salary_person_setups, :is_send_flyer_science if SalaryPersonSetup.attribute_names.include?('is_send_flyer_science')
  	remove_column :salary_person_setups, :is_send_airline_fee if SalaryPersonSetup.attribute_names.include?('is_send_airline_fee')
  	remove_column :salary_person_setups, :is_send_transport_fee if SalaryPersonSetup.attribute_names.include?('is_send_transport_fee')

  	add_column :salary_person_setups, :is_send_flyer_science, :boolean, default: true, index: true, comment: '是否发放飞行驾驶技术津贴'
  	add_column :salary_person_setups, :is_send_airline_fee, :boolean, default: true, index: true, comment: '是否发放空勤灶'
  	add_column :salary_person_setups, :is_send_transport_fee, :boolean, default: true, index: true, comment: '是否发放交通费'
  end
end

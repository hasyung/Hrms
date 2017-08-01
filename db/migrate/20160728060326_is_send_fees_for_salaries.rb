class IsSendFeesForSalaries < ActiveRecord::Migration
  def change
  	add_column :salary_person_setups, :is_send_airline_fee, :boolean, default: false, index: true, comment: '是否发放空勤灶'  if SalaryPersonSetup.attribute_names.exclude?('is_send_airline_fee')
  	add_column :salary_person_setups, :is_send_transport_fee, :boolean, default: false, index: true, comment: '是否发放交通费'  if SalaryPersonSetup.attribute_names.exclude?('is_send_transport_fee')
  end
end

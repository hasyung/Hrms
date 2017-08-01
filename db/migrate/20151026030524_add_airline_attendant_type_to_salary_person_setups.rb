class AddAirlineAttendantTypeToSalaryPersonSetups < ActiveRecord::Migration
  def change
    add_column :salary_person_setups, :airline_attendant_type, :string, index: true, comment: '表示空勤飞行还是空勤地面'
    remove_column :salary_person_setups, :is_service_fly
    remove_column :salary_person_setups, :is_service_land
  end
end

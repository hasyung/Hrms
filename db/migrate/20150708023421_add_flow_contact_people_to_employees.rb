class AddFlowContactPeopleToEmployees < ActiveRecord::Migration
  def change
    add_column :employees, :flow_contact_people, :string, default: []
  end
end

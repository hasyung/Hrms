class AddJoinPartyDateToEmployees < ActiveRecord::Migration
  def change
    add_column :employees, :join_party_date, :date
  end
end

class AddChangeContractDateAndChangeContractSystemDateToEmployees < ActiveRecord::Migration
  def change
    add_column :employees, :change_contract_date, :date
    add_column :employees, :change_contract_system_date, :date
  end
end

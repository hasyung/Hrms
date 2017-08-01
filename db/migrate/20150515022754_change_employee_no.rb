class ChangeEmployeeNo < ActiveRecord::Migration
  def change
    change_column :contracts, :employee_no, :string, default: nil;
  end
end

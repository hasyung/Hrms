class ChangePcategoryToEmployees < ActiveRecord::Migration
  def change
    change_column :employees, :pcategory, :string, default: '员工'
  end
end

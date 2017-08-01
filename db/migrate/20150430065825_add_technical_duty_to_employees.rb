class AddTechnicalDutyToEmployees < ActiveRecord::Migration
  def change
    add_column :employees, :technical_duty, :string #技术职务
  end
end

class AddNationalityForEmployees < ActiveRecord::Migration
  def change
  	add_column :employees, :nationality, :string, index: true, comment: '国籍'
  end
end

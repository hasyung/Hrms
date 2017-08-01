class AddOldEducationDataToEmployees < ActiveRecord::Migration
  def change
    add_column :employees, :old_education_data, :string, comment: '旧的学历信息'
  end
end

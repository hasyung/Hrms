class AddChangeEducationDateToEmployees < ActiveRecord::Migration
  def change
    add_column :employees, :change_education_date, :date, index: true, comment: '最后一次学历的变更日期'
  end
end

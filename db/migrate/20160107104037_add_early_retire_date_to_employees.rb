class AddEarlyRetireDateToEmployees < ActiveRecord::Migration
  def change
    add_column :employees, :early_retire_date, :date, index: true, comment: '退养时间'
  end
end

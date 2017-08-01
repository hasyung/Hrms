class AddKeepToSalaryOverviews < ActiveRecord::Migration
  def change
    rename_column :salary_overviews, :base, :basic
    add_column :salary_overviews, :keep, :decimal, precision: 10, scale: 2, index: true, comment: '保留工资'
  end
end

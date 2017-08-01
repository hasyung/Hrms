class AddBirthToSalaryOverviews < ActiveRecord::Migration
  def change
    add_column :salary_overviews, :birth, :decimal, precision: 10, scale: 2, index: true, comment: '生育保险冲抵'
  end
end

class AddAnyColumnForSalaries < ActiveRecord::Migration
  def change
    add_column :salary_person_setups, :join_salary_scal_date, :date, index: true, comment: '薪酬到岗时间'

    add_column :basic_salaries, :notes, :string, index: true, comment: '计算过程备注'
    add_column :keep_salaries, :notes, :string, index: true, comment: '计算过程备注'
    add_column :performance_salaries, :notes, :string, index: true, comment: '计算过程备注'
    add_column :hours_fees, :notes, :string, index: true, comment: '计算过程备注'
    add_column :allowances, :notes, :string, index: true, comment: '计算过程备注'
    add_column :land_allowances, :notes, :string, index: true, comment: '计算过程备注'
    add_column :transport_fees, :notes, :string, index: true, comment: '计算过程备注'
    add_column :salary_overviews, :notes, :string, index: true, comment: '计算过程备注'
  end
end

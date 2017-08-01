class AddSalarySetBookToEmployees < ActiveRecord::Migration
  def change
    add_column :employees, :salary_set_book, :string, index: true, comment: '员工帐套'
    add_column :basic_salaries, :salary_set_book, :string, index: true, comment: '员工帐套'
    add_column :keep_salaries, :salary_set_book, :string, index: true, comment: '员工帐套'
    add_column :performance_salaries, :salary_set_book, :string, index: true, comment: '员工帐套'
    add_column :hours_fees, :salary_set_book, :string, index: true, comment: '员工帐套'
    add_column :allowances, :salary_set_book, :string, index: true, comment: '员工帐套'
    add_column :land_allowances, :salary_set_book, :string, index: true, comment: '员工帐套'
    add_column :rewards, :salary_set_book, :string, index: true, comment: '员工帐套'
    add_column :transport_fees, :salary_set_book, :string, index: true, comment: '员工帐套'
    add_column :salary_overviews, :salary_set_book, :string, index: true, comment: '员工帐套'
  end
end

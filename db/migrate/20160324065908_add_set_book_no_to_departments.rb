class AddSetBookNoToDepartments < ActiveRecord::Migration
  def change
    add_column :departments, :set_book_no, :string
  end
end

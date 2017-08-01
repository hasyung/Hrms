class AddSortNoToTables < ActiveRecord::Migration
  def change
    remove_column :employees, :master_department_serial_number, :string

    add_column :departments, :d1_sort_no, :integer, default: 0
    add_column :departments, :d2_sort_no, :integer, default: 0
    add_column :departments, :d3_sort_no, :integer, default: 0

    add_column :positions, :sort_no, :integer

    add_column :employees, :sort_no, :integer
    add_column :employees, :department_id, :integer
  end
end

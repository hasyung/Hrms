class AddCategoryToEmployeePositions < ActiveRecord::Migration
  def change
    add_column :employee_positions, :category, :string, default: '主职'
  end
end

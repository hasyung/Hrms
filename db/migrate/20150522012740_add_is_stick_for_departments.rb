class AddIsStickForDepartments < ActiveRecord::Migration
  def change
    add_column :departments, :is_stick, :boolean, default: false, index: true
  end
end

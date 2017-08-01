class AddFullNameForDepartments < ActiveRecord::Migration
  def change
    add_column :departments, :full_name, :string, index: true

    Department.all.each do |department|
      department.get_full_name
      department.save
    end
  end
end

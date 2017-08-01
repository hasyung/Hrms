class AddDepartmentNameToReports < ActiveRecord::Migration
  def change
    add_column :reports, :department_name, :string, index: true, comment: '部门名称'
  end
end

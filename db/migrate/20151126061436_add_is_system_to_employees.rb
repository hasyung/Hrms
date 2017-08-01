class AddIsSystemToEmployees < ActiveRecord::Migration
  def change
    add_column :employees, :is_system, :boolean, default: false, index: true, comment: '系统管理员'
  end
end

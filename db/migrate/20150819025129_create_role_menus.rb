class CreateRoleMenus < ActiveRecord::Migration
  def change
    create_table :role_menus do |t|
      t.string :role_name, null: false, index: true, comment: "角色名称"
      t.text :menus, comment: "菜单"
      t.integer :level, default: 0, index: true, comment: "优先级"

      t.timestamps null: false
    end
  end
end

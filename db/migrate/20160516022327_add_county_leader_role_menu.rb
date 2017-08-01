class AddCountyLeaderRoleMenu < ActiveRecord::Migration
  def change
  	role_menu = RoleMenu.find_or_create_by(role_name: 'county_leader')
    role_menu.update(level: 33)
  end
end

class ChangeRoleMenusLevel < ActiveRecord::Migration
  def change
  	welfare_member = RoleMenu.find_by(role_name: 'welfare_member')
  	welfare_member.update(level: 99) if welfare_member

  	hr_normal = RoleMenu.find_by(role_name: 'hr_normal')
  	hr_normal.update(level: 99) if hr_normal

  	new_employee = RoleMenu.find_by(role_name: 'new_employee')
  	new_employee.update(level: 999) if new_employee

  	family_leader = RoleMenu.find_by(role_name: 'family_leader')
  	family_leader.update(level: 33) if family_leader
  end
end

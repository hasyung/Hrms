namespace :init do
  desc "添加福利室管理员"

  task welfare_permission_group: :environment do
    PermissionGroup.create(name: 'welfare_member')
  end
end

namespace :init do
  desc 'init permissions'
  task permission: :environment do
    @permissions = YAML.load(File.read("#{Rails.root}/config/permission.yml"))

    level = 1
    @permissions.each do |category, permissions|
      permissions.each do |permission|
        permission.merge!({category: category})
        records = Permission.where(controller: permission["controller"], action: permission["action"])

        records.last.destroy if records.size > 1

        if records.present?
          records.first.update(name: permission["name"], level: level)
        else
          permission.merge!({level: level})
          p = Permission.new(permission)
          unless p.save
            puts p.errors.messages
          end
        end
      end
      level += 1
    end
    
    Permission.where(level: nil).delete_all

    # 删除多余的permission
    diff_attr = Permission.pluck(:controller, :action).map{|permission| permission.join("-")} - @permissions.values.flatten.map{|permission| "#{permission['controller']}-#{permission['action']}"}
    diff_attr.each do |attr|
      controller, action = attr.split('-')
      Permission.find_by(controller: controller, action: action).try(:destroy)
    end

    p '!!!!完成权限同步!!!!'
  end

  desc "删除重复的permission"
  task delete_permission: :environment do
    repeated_permission_ids = Permission.all.pluck(:controller, :action, :id)
      .group_by{|attr| "#{attr[0]}-#{attr[1]}"}
      .map{|key, val| val[1][2] if val.count > 1}
      .compact

    Permission.where(id: repeated_permission_ids).destroy_all  
  end

  task permission_file: :environment do
    @permissions = YAML.load(File.read("#{Rails.root}/config/permission.yml"))

    @permissions.each do |category, permissions|
      permissions.each_with_index do |permission, index|
        record = Permission.find_by(controller: permission["controller"], action: permission["action"])
        @permissions[category][index]["name"] = record.name
      end
    end

    File.open("#{Rails.root}/config/permission.yml", 'w') {|f| f.write @permissions.to_yaml }
  end

end

namespace :init do
  desc "生成一个更新权限的sql文件"

  task update_permission_sql_file: :environment do 
    File.open("update_permission.sql", "w"){|file| file.truncate(0)} if File.exist?("update_permission.sql")
    Permission.all.each do |permission|
      `echo "UPDATE permissions SET name='#{permission.name}' WHERE controller='#{permission.controller}' AND action='#{permission.action}'" >> update_permission.sql`
    end
  end
end
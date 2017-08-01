module Snapshotable
  extend ActiveSupport::Concern

  included do
    #
  end

  module ClassMethods
    def take_snapshot(current_version, drop_exists = true)
      model = self.to_s.downcase
      old_db = "Hrms_#{Rails.env.to_s}"
      new_db = "Hrms_#{Rails.env.to_s}_#{current_version}"
      sql_file = "/tmp/#{current_version}.sql"
      config = YAML.load(File.read(Rails.root.to_s + "/config/database.yml"))[Rails.env]

      mysql_user = config["username"]
      mysql_password = config["password"]

      #在部署的服务器home目录下创建~/.my.cnf文件内容是:
      #[mysqldump]
      #user=数据库用户名
      #password=对应的密码
      #[mysql]
      #user=数据库用户名
      #password=对应的密码

      `mysqldump -u#{mysql_user} -p#{mysql_password} --databases #{old_db} > #{sql_file}`
      IO.write(sql_file, File.open(sql_file){|f|f.read.gsub(old_db, new_db)})
      `echo "drop database if exists #{new_db}" | mysql -u#{mysql_user};` if drop_exists
      `echo "create database #{new_db} charset utf8" | mysql -u#{mysql_user}`
      `mysql -u#{mysql_user} --database #{new_db} < #{sql_file}`
      `rm /tmp/#{current_version}.sql`
      Snapshot.create(model: model, version: current_version, data: {})
    end
  end
end

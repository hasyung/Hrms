RAILS_ROOT = "/var/www/hrms/current"

God.watch do |w|
  w.name = "hrms_redis"

  w.start = "sudo redis-server /etc/redis/redis.conf"
  w.stop = "sudo killall redis-server"
  w.restart = "sudo killall redis-server && sudo redis-server /etc/redis/redis.conf"

  w.pid_file = File.join(RAILS_ROOT, "/tmp/pids/redis.pid")

  w.behavior(:clean_pid_file)
end

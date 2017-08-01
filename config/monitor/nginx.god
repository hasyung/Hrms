RAILS_ROOT = "/var/www/hrms/current"

God.watch do |w|
  w.name = "hrms_nginx"

  w.start = "sudo /usr/local/nginx/sbin/nginx"
  w.stop = "sudo /usr/local/nginx/sbin/nginx -s stop"
  w.restart = "sudo /usr/local/nginx/sbin/nginx -s stop && sudo /usr/local/nginx/sbin/nginx"

  w.pid_file = File.join(RAILS_ROOT, "/tmp/pids/nginx.pid")

  w.behavior(:clean_pid_file)
end

APP_ROOT = '/var/www/hrms/current/'

ENV["BUNDLE_GEMFILE"] = File.join(APP_ROOT, "Gemfile")

on_worker_boot do
  Redis.current.client.reconnect
  $redis = Redis.current
end

on_restart do
  Redis.current.client.reconnect
  $redis = Redis.current
end

environment "production"
threads 8, 32
workers 8

bind "tcp://0.0.0.0:4000"
bind "unix:///tmp/hrms.sock"

pidfile "#{APP_ROOT}/tmp/pids/puma.pid"
state_path "#{APP_ROOT}/tmp/pids/puma.state"
daemonize true
preload_app!
activate_control_app

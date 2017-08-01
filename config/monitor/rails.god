RAILS_ROOT = "/var/www/hrms/current"
SHARED_ROOT = "/var/www/hrms/shared"

God.watch do |w|
  w.name = "hrms_rails"

  w.start = "RAILS_ENV=production rvm ruby-2.1.5@rails-4.2.0 do bundle exec puma -C #{SHARED_ROOT}/puma.rb --daemon"
  w.stop = "kill -TERM `cat #{RAILS_ROOT}/tmp/pids/puma.pid`"
  w.restart = "kill -USR2 `cat #{RAILS_ROOT}/tmp/pids/puma.pid`"

  w.pid_file = File.join(RAILS_ROOT, "/tmp/pids/puma.pid")

  w.behavior(:clean_pid_file)

  w.start_if do |start|
    start.condition(:process_running) do |c|
      c.interval = 5.seconds
      c.running = false
    end
  end

  w.lifecycle do |on|
    on.condition(:flapping) do |c|
      c.to_state = [:start, :restart]
      c.times = 5
      c.within = 5.minute
      c.transition = :unmonitored
      c.retry_in = 10.minutes
      c.retry_times = 5
      c.retry_within = 2.hours
    end
  end
end

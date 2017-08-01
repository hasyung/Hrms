$redis.lock("test", life: 120, acquire: 3) do
  1.upto(120) do |index|
    puts index
    sleep(1)
  end
end

##################################################################

$redis.lock("test", acquire: 3) do |lock|
  1.upto(120) do |index|
    puts index
    sleep(1)
    lock.extend_life(1)
  end
end

##################################################################

begin
  $redis.lock("test", life: 120, acquire: 3) do
    puts "success"
  end
rescue Redis::Lock::LockNotAcquired => ex
  puts "failed: #{ex}"
end
module Subscriber
  extend self

  # delegate to ActiveSupport::Notifications.subscribe
  # Subscriber.subscribe("test") do |event|
  # 	puts event.payload.inspect
  # end

  def subscribe(event_name)
    if block_given?
      ActiveSupport::Notifications.subscribe(event_name) do |*args|
        event = ActiveSupport::Notifications::Event.new(*args)
        yield(event)
      end
    end
  end
end

# require 'exception_notification/rails'

# ExceptionNotification.configure do |config|
#   # Ignore additional exception types.
#   # ActiveRecord::RecordNotFound, AbstractController::ActionNotFound and ActionController::RoutingError are already added.
#   # config.ignored_exceptions += %w{ActionView::TemplateError CustomError}

#   # Adds a condition to decide when an exception must be ignored or not.
#   # The ignore_if method can be invoked multiple times to add extra conditions.
#   # config.ignore_if do |exception, options|
#   #   not Rails.env.production?
#   # end

#   # Notifiers =================================================================

#   # Email notifier sends notifications by email.
#   config.add_notifier :email, {
#     :email_prefix         => "[ERROR] ",
#     :sender_address       => %{"Notifier" <notifier@example.com>},
#     :exception_recipients => %w{exceptions@example.com}
#   }

#   # Campfire notifier sends notifications to your Campfire room. Requires 'tinder' gem.
#   # config.add_notifier :campfire, {
#   #   :subdomain => 'my_subdomain',
#   #   :token => 'my_token',
#   #   :room_name => 'my_room'
#   # }

#   # HipChat notifier sends notifications to your HipChat room. Requires 'hipchat' gem.
#   # config.add_notifier :hipchat, {
#   #   :api_token => 'my_token',
#   #   :room_name => 'my_room'
#   # }

#   # Webhook notifier sends notifications over HTTP protocol. Requires 'httparty' gem.
#   # config.add_notifier :webhook, {
#   #   :url => 'http://example.com:5555/hubot/path',
#   #   :http_method => :post
#   # }

# end

require 'exception_notification/sidekiq'
require 'socket'

# 自定义 notifier(slack)
module ExceptionNotifier
  class SlackNotifier
    attr_accessor :notifier

    def initialize(options)
      begin
        webhook_url = options.fetch(:webhook_url)
        @message_opts = options.fetch(:additional_parameters, {})
        @notifier = Slack::Notifier.new webhook_url, options
      rescue
        @notifier = nil
      end
    end

    def call(exception, options={})
      message = [
        "项目: 川航人力资源系统-报错",
        "主机: #{Socket.gethostname}",
        "地址: #{IPSocket.getaddress(Socket.gethostname)}",
        "时间: #{Time.now.strftime("%Y-%m-%d %H:%M")}",
        "参数: #{options.to_s}",
        "堆栈: #{exception.backtrace.join("\n")}",
        "--------------------------------------------"
      ].join("\n\n")

      @notifier.ping(message, @message_opts) if valid?
    end

    protected

    def valid?
      !@notifier.nil?
    end
  end
end

ExceptionNotification.configure do |config|
  config.add_notifier :slack, {
    :webhook_url => "https://hooks.slack.com/services/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",
    :channel     => "#scal_hrms",
    :username    => "川航人力资源系统"
  }
end

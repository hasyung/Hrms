class MessagePushClient
  attr_reader :client, :package, :room_id

  # package 包名
  # room_id 房间号
  def initialize(package, room_id)
    config = PushServerSetting.to_hash
    @client = ::PomeloClient::Client.new(config['host'], config['port'])
    @package = package
    @room_id = room_id
  end

  #username通常为员工编号，这个参数需要具备唯一性
  def connect_server(username)
    hash = {username: username, rid: "#{@room_id}"}
    @client.request('connector.entryHandler.enter', hash) do |m|
      puts "connector.entryHandler.enter => #{m}"
    end
  end

  # 调用方式
  # 推送普通消息 client.user_message
  # 推送系统配置 client.system_config
  # 推送工作流程处理消息 client.workflow_step_action
  # 推送聊天消息 client.chat_message
  def method_missing(method_name, *args, &block)
    keys = ["user_message", "system_config", "workflow", "chat_message"]

    if keys.include?(method_name.to_s)
      # see http://code.cdavatar.com:8080/wangbo/MessagePushServer/wikis/home
      # package 包名
      # username 用户名
      # content 推送内容，消息标识不同而不同，请看文档
      # message_key 消息标识
      hash = {package: @package,
              username: args[0][:username] || "system",
              content: args[0][:content], 
              target: args[0][:target] || '*',
              message_key: method_name.to_s}
      puts JSON.pretty_generate(hash) if Rails.env.test?
      return send_message(hash)
    end

    super
  end

  def self.instance_for(backend_username)
    client = MessagePushClient.new MESSAGE_PUSH_PACKAGE, MESSAGE_PUSH_ROOM_ID
    client.connect_server(backend_username)
    yield client if block_given?
    client.disconnect_server 
  end

  def disconnect_server
    @client.close
  end

  private

  def send_message(hash)
    client.request('message.messageHandler.send', hash) do |m|
      puts "message.messageHandler.send => #{m}"
    end
  end
end


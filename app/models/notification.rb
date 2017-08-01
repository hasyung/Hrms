# == Schema Information
#
# Table name: notifications
#
#  id           :integer          not null, primary key
#  category     :string(255)
#  body         :string(255)
#  confirmed    :boolean          default("0")
#  confirmed_at :time
#  employee_id  :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_notifications_on_category      (category)
#  index_notifications_on_confirmed     (confirmed)
#  index_notifications_on_confirmed_at  (confirmed_at)
#  index_notifications_on_employee_id   (employee_id)
#

class Notification < ActiveRecord::Base
  validates_presence_of :category, :body

  belongs_to :employee

  # Scopes
  default_scope -> {order('created_at DESC')}
  scope :category, ->(category) {where(category: category)}
  scope :unread, -> {where(confirmed: false)}

  # 发送消息通知
  def self.send_user_message(employee_id, category, body)
    employee = Employee.find(employee_id)

    case category
    when 'contract', 'agreement'
      notification = Notification.create_with(body: body).find_or_create_by(confirmed: false, employee_id: employee_id, category: category)
    else
      notification = Notification.create(employee_id: employee_id, category: category, body: body)
    end

    target = employee.employee_no.blank? ? '*' : message_device_client(employee.employee_no)

    hash = {title: category, body: body}
    content = {
      unread_count: employee.notifications.unread.count,
      latest_message: hash
    }

    MessagePushClient.instance_for(backend_username) do |client|
      client.user_message(content: content, target: target)
    end
  end

  # 发送消息提醒
  def self.send_workflow_messages(employee_id, category)
    employee = Employee.find(employee_id)
    target = employee.employee_no.blank? ? '*' : message_device_client(employee.employee_no)

    count = Flow.where("reviewer_ids like '%- #{employee_id}\n%' and type = '#{category}'").count
    content = {
      type: category,
      count: count,
      route_state: FlowSetting.to_hash[category]["route_state"] || '',
      oldest_at: Time.now.to_s(:db),
      name: I18n.t("flow.type.#{category}")
    }

    MessagePushClient.instance_for(backend_username) do |client|
      client.workflow(content: content, target: target)
    end
  end

  # 发送系统消息，data参数是要发送的数据
  def self.send_system_message(employee_id, data)
    employee = Employee.find(employee_id)
    target = employee.employee_no.blank? ? '*' : message_device_client(employee.employee_no)

    MessagePushClient.instance_for(backend_username) do |client|
      client.system_config(content: data, target: target)
    end
  end

  private
  def self.backend_username
    'system'
  end

  def self.message_device_client(employee_no)
    'web_' + employee_no
  end
end


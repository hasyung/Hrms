# == Schema Information
#
# Table name: flows
#
#  id             :integer          not null, primary key
#  name           :string(255)
#  sponsor_id     :integer
#  receptor_id    :integer
#  reviewer_ids   :string(255)
#  viewer_ids     :string(255)
#  type           :string(255)
#  workflow_state :string(255)      default("new")
#  form_data      :string(255)
#  relation_data  :string(255)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

class Flow < ActiveRecord::Base
  include WorkflowUser

  serialize :reviewer_ids, Array
  serialize :viewer_ids, Array
  serialize :leave_date_record, Hash
  serialize :deduct_leave_date, Hash
  # serialize :form_data, Hash

  scope :leaves, -> { where("type in (?)", Flow.leave_types)}
  scope :actived, -> { where("workflow_state = ?", "actived") }

  has_many :flow_nodes, class_name: "WorkflowEvent"
  has_many :flow_attachments, dependent: :destroy

  belongs_to :sponsor, class_name: 'Employee', foreign_key: "sponsor_id"
  belongs_to :receptor, class_name: 'Employee', foreign_key: "receptor_id"

  after_update :add_dinner_change, if: -> (flow){Flow::LEAVE_TYPES.include?(flow.type) && flow.workflow_state_changed? && flow.workflow_state=='accepted'}

  # 请假
  LEAVE_TYPES = %w(
  Flow::AccreditLeave        Flow::AnnualLeave    Flow::FuneralLeave
  Flow::HomeLeave            Flow::MarriageLeave  Flow::MaternityLeave
  Flow::MiscarriageLeave     Flow::PersonalLeave  Flow::PrenatalCheckLeave
  Flow::RearNurseLeave       Flow::SickLeave      Flow::SickLeaveInjury
  Flow::SickLeaveNulliparous Flow::WomenLeave     Flow::OccupationInjury
  Flow::PublicLeave          Flow::LactationLeave Flow::OffsetLeave
  Flow::MaternityLeaveBreastFeeding Flow::MaternityLeaveDystocia
  Flow::MaternityLeaveLateBirth     Flow::MaternityLeaveMultipleBirth
  Flow::RecuperateLeave
  )

  # 带薪假
  SALARY_LEAVE_TYPES = %w(Flow::AnnualLeave Flow::FuneralLeave Flow::LactationLeave 
    Flow::MarriageLeave Flow::MaternityLeave Flow::MaternityLeaveBreastFeeding 
    Flow::MaternityLeaveDystocia Flow::MaternityLeaveLateBirth Flow::MaternityLeaveMultipleBirth 
    Flow::MiscarriageLeave Flow::OccupationInjury Flow::OffsetLeave Flow::PrenatalCheckLeave 
    Flow::RearNurseLeave Flow::RecuperateLeave Flow::WomenLeave)

  WORKING_DAYS_LEAVE_FLOW = %w(Flow::AnnualLeave Flow::OffsetLeave)

  EMPLOYEE_FILTER_STATES = %w(accepted checking actived) #在人员花名册列表可过滤的状态

  EMPLOYEE_FILTER_TYPES = %w(Flow::Retirement Flow::Dismiss Flow::EarlyRetirement Flow::EmployeeLeaveJob) #不允许员工多次申请的流程类型

  BATCH_CREATE_TYPES = %w(Flow::Retirement) #可批量创建类型

  default_scope {order('created_at desc')}

  def flow_end?
    ["accepted", 'rejected', 'actived', 'repeal'].include?(self.workflow_state)
  end

  def todo_message
    receptor = self.receptor
    condition = {
      receptor_name: receptor.name,
      department_position_name: "#{receptor.department.full_name},
      #{receptor.master_position.name}"
    }

    if Flow.leave_types.include?(self.type)
      condition.merge!(leave_desc: "#{Time.parse(self.start_time).strftime('%Y-%m-%d')}起，时长#{self.vacation_days}天")
    end

    I18n.t("flow.#{self.type}.todo_message", condition)
  end

  def get_index_for(reviewer_id)
    index = 0

    self.reviewer_ids.each_with_index do |id, idx|
      index = idx and break if id.class == Array && id.include?(reviewer_id)
      index = idx and break if id == reviewer_id
    end

    return index
  end

  def leave_job_flow_state
    self.leave_job_state ? "已发起" : "未发起"
  end

  def self.get_messages_count_by_employee current_employee
    {
      user_message: self.get_user_message_by_employee(current_employee),
      workflows: self.get_user_workflow_messages_by_employee(current_employee)
    }
  end

  def self.get_user_message_by_employee(current_employee)
    unread_notifications = current_employee.notifications.order('created_at desc')
    latest_message = unread_notifications.first

    hash = {unread_count: unread_notifications.unread.count}
    hash[:latest_message] = {title: latest_message.category, content: latest_message.body} if latest_message.present?
    hash
  end

  def self.get_user_workflow_messages_by_employee(current_employee)
    workflows = Flow.where("reviewer_ids like '%- #{current_employee.id}\n%'").order('created_at desc')

    workflows.group_by{|flow|flow.type}.inject([]) do |arr, flows|
      arr << {
        type: flows[0],
        count: flows[1].size,
        route_state: FlowSetting.to_hash[flows[0]]["route_state"] || '',
        oldest_at: flows[1].first.created_at.to_time.to_s(:db),
        name: flows[1].first.name
      }
    end
  end

  def self.leave_types
    LEAVE_TYPES
  end

  def self.batch_create_types
    BATCH_CREATE_TYPES
  end

  def self.employee_filter_states
    EMPLOYEE_FILTER_STATES
  end

  def self.employee_filter_types
    EMPLOYEE_FILTER_TYPES
  end

  def can_supplement?
    FlowSetting["#{self.type}"]["supplement"]
  end

  def active
    self.update(workflow_state: 'actived')
  end

  def add_dinner_change
    if self.end_time && self.start_time && Date.has_natural_month?(self.end_time.to_time, self.start_time.to_time)
      # 添加工作餐变动信息
      hash = {employee_id: self.receptor_id, category: '长期请假', leave_type: I18n.t("flow.type.#{self.type}"),
        start_date: self.start_time.to_date, end_date: self.end_time.to_date}
      Publisher.broadcast_event('DINNER_CHANGE', hash)
    end
  end
end

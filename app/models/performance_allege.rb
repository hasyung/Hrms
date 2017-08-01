class PerformanceAllege < ActiveRecord::Base
  belongs_to :performance
  has_many :attachments, class_name: "PerformanceAllegeAttachment",
    foreign_key: 'performance_allege_id', dependent: :destroy

  after_save :send_message, if: -> (allege){allege.outcome_changed?&&(allege.outcome=='通过'||allege.outcome=='驳回')}

  private
  def send_message
    employee_id = self.performance.employee_id
    duration = self.performance.category=='year' ? self.performance.assess_time.year.to_s+'年' : self.performance.assess_time.strftime("%Y-%m")
    if self.outcome == '通过'
      Notification.send_user_message(employee_id, "general", "您考核时段#{duration}的绩效申述已通过，绩效调整为#{self.performance.result}")
    else
      Notification.send_user_message(employee_id, "general", "您考核时段#{duration}的绩效申述已驳回")
    end
  end
end

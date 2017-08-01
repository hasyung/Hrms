#女工假
class Flow::WomenLeave < Flow
  include Workflowable
  include Leaveable
  
  ATTRIBUTES = [:start_time, :vacation_days, :reason, :end_time]

  store :form_data, :accessors => ATTRIBUTES
  # validate :presence_columns

  def presence_columns
    errors.add(:start_time, I18n.t("errors.messages.#{self.class.to_s}.start_time")) if self.start_time.blank?
    errors.add(:vacation_days, I18n.t("errors.messages.#{self.class.to_s}.vacation_days")) if self.vacation_days.blank?
    errors.add(:reason, I18n.t("errors.messages.#{self.class.to_s}.reason")) if self.reason.blank?
  end

  def self.initiator(params)
    user_id = params[:receptor_id] || params[:sponsor_id]
    
    Employee.find(user_id).is_female?
  end
end
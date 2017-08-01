#产假(流产)
class Flow::MiscarriageLeave < Flow
  include Workflowable
  include Leaveable
  
  ATTRIBUTES = [:during_pregnancy, :start_time, :end_time, :vacation_days, :reason]

  store :form_data, :accessors => ATTRIBUTES
  # validate :presence_columns

  def presence_columns
    errors.add(:start_time, I18n.t("errors.messages.#{self.class.to_s}.start_time")) if self.start_time.blank?
    errors.add(:end_time, I18n.t("errors.messages.#{self.class.to_s}.end_time")) if self.end_time.blank?
    errors.add(:vacation_days, I18n.t("errors.messages.#{self.class.to_s}.vacation_days")) if self.vacation_days.blank?
    errors.add(:reason, I18n.t("errors.messages.#{self.class.to_s}.reason")) if self.reason.blank?
    errors.add(:during_pregnancy, I18n.t("errors.messages.#{self.class.to_s}.during_pregnancy")) if self.during_pregnancy.blank?
  end
  
  def self.initiator(params)
    user_id = params[:receptor_id] || params[:sponsor_id]
    
    Employee.find(user_id).is_female?
  end
end
#婚假
class Flow::MarriageLeave < Flow
  include Workflowable
  include Leaveable

  ATTRIBUTES = [:marriage_time, :start_time, :end_time, :vacation_days, :reason]

  store :form_data, :accessors => ATTRIBUTES
  validate :presence_columns

  def presence_columns
    # errors.add(:start_time, I18n.t("errors.messages.#{self.class.to_s}.start_time")) if self.start_time.blank?
    # errors.add(:end_time, I18n.t("errors.messages.#{self.class.to_s}.end_time")) if self.end_time.blank?
    # errors.add(:vacation_days, I18n.t("errors.messages.#{self.class.to_s}.vacation_days")) if self.vacation_days.blank?
    # errors.add(:reason, I18n.t("errors.messages.#{self.class.to_s}.reason")) if self.reason.blank?
    # errors.add(:marriage_time, I18n.t("errors.messages.#{self.class.to_s}.marriage_time")) if self.marriage_time.blank?
    errors.add(:attachment_ids, I18n.t("errors.messages.#{self.class.to_s}.attachment_ids")) if self.flow_attachments.empty?
  end
end

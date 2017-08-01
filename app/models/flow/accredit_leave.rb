#派驻人员休假
class Flow::AccreditLeave < Flow
  include Workflowable
  include Leaveable

  ATTRIBUTES = [:start_time, :end_time, :vacation_days, :reason]

  store :form_data, :accessors => ATTRIBUTES

  # validate :presence_columns

  def presence_columns
    errors.add(:start_time, I18n.t("errors.messages.#{self.class.to_s}.start_time")) if self.start_time.blank?
    errors.add(:end_time, I18n.t("errors.messages.#{self.class.to_s}.end_time")) if self.end_time.blank?
    errors.add(:vacation_days, I18n.t("errors.messages.#{self.class.to_s}.vacation_days")) if self.vacation_days.blank?
    errors.add(:reason, I18n.t("errors.messages.#{self.class.to_s}.reason")) if self.reason.blank?
  end

  def active_workflow(validate = true)
    self.receptor.force_reduce_year_days("派驻人员休假")
    self.update(workflow_state: 'actived')
    add_leave_days
  end
end

#年假
class Flow::AnnualLeave < Flow
  include Workflowable
  include Leaveable

  ATTRIBUTES = [:start_time, :end_time, :vacation_days, :reason]

  store :form_data, :accessors => ATTRIBUTES
  # validate  :check_vacation_days
  # validate :presence_columns

  def presence_columns
    errors.add(:start_time, I18n.t("errors.messages.#{self.class.to_s}.start_time"))       if self.start_time.blank?
    errors.add(:end_time, I18n.t("errors.messages.#{self.class.to_s}.end_time"))           if self.end_time.blank?
    errors.add(:vacation_days, I18n.t("errors.messages.#{self.class.to_s}.vacation_days")) if self.vacation_days.blank?
    errors.add(:reason, I18n.t("errors.messages.#{self.class.to_s}.reason"))               if self.reason.blank?
  end

  def active_workflow(validate = true)
    force_reduce_days
    self.update(workflow_state: 'actived')
    add_leave_days
  end

  def restore_reduce_days
    records = self.leave_date_record.values
    vacation_days = records.inject(0) do |days, record|
      days += record["vacation_days"] if record["leave_type"] != self.type
      days
    end

    self.receptor.add_year_days(vacation_days)
  end

  def force_reduce_days
    records = self.leave_date_record.values
    vacation_days = records.inject(0) do |days, record|
      days += record["vacation_days"] if record["leave_type"] == self.type
      days
    end

    self.receptor.reduce_year_days(vacation_days)
  end

  private
  def check_vacation_days
    total_year_days = self.receptor.total_year_days

    if vacation_days && vacation_days.to_i > total_year_days
      errors.add(:vacation_days, "你的请假天数超过了你的年假天数")
    end
  end
end

#病假
class Flow::SickLeave < Flow
  include Workflowable
  include Leaveable

  ATTRIBUTES = [:start_time, :end_time, :vacation_days, :reason]

  store :form_data, :accessors => ATTRIBUTES
  # validate :presence_columns

  def presence_columns
    errors.add(:start_time, I18n.t("errors.messages.#{self.class.to_s}.start_time"))       if self.start_time.blank?
    errors.add(:end_time, I18n.t("errors.messages.#{self.class.to_s}.end_time"))           if self.end_time.blank?
    errors.add(:vacation_days, I18n.t("errors.messages.#{self.class.to_s}.vacation_days")) if self.vacation_days.blank?
    errors.add(:reason, I18n.t("errors.messages.#{self.class.to_s}.reason"))               if self.reason.blank?
  end

  def active_job
    force_reduce_days
    self.active
    add_leave_days
  end

  def restore_reduce_days
    records = self.leave_date_record.values
    vacation_days = records.inject(0) do |days, record|
      days += record["vacation_days"] if record["leave_type"] != self.type
      days
    end

    self.receptor.restore_reduce_year_days("病假") if can_restore_or_reduce?(vacation_days)
  end

  def force_reduce_days
    records = self.leave_date_record.values
    vacation_days = records.inject(0) do |days, record|
      days += record["vacation_days"] if record["leave_type"] == self.type
      days
    end

    self.receptor.force_reduce_year_days("病假") if can_restore_or_reduce?(vacation_days)
  end

  protected
  def can_restore_or_reduce?(vacation_days)
    working_years = self.receptor.scal_working_years || 0

    ((2..9).include?(working_years) && vacation_days >= 60) || \
    ((10..19).include?(working_years) && vacation_days >= 90) || \
    (working_years >= 20 && vacation_days >= 120)
  end
end

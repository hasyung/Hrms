#补休假
class Flow::OffsetLeave < Flow
  include Workflowable
  include Leaveable

  ATTRIBUTES = [:start_time, :end_time, :vacation_days, :reason]

  store :form_data, :accessors => ATTRIBUTES

  # validate :check_days

  def active_workflow
    force_reduce_days
    self.active
    add_leave_days
  end

  def force_reduce_days
    records = self.leave_date_record.values
    vacation_days = records.inject(0) do |days, record|
      days += record["vacation_days"] if record["leave_type"] == self.type
      days
    end

    self.receptor.reduce_offset_days(vacation_days)
  end

  private
  def check_days
    offset_days = self.receptor.offset_days

    if vacation_days && vacation_days.to_i > offset_days
      errors.add(:vacation_days, "你的请假天数超过了你剩余补休假天数")
    end
  end
end

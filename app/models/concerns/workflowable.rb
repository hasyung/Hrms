module Workflowable
  extend ActiveSupport::Concern

  included do
    before_create do
      self.name = I18n.t("flow.type.#{self.type}")
    end

    def next_purpose(opinion)
      if Flow::LEAVE_TYPES.include?(self.type)
        self.update(workflow_state: "accepted") if opinion == true

        if opinion == true && DateTime.now > self.start_time.to_datetime
          self.respond_to?(:active_job) ? self.active_job : self.active_workflow
        end
      else
        self.active_workflow if opinion == true
      end

      self.update(workflow_state: "rejected") if opinion == false
    end

    def active_workflow(validate = true)
      if validate
        self.update(workflow_state: 'actived')
      else
        self.update_columns(workflow_state: 'actived')
      end
      ChangeRecord.save_record(change_record_category, Employee.unscoped{ self.receptor }).send_notification if change_record_category
      ChangeRecordWeb.save_record(change_record_category, Employee.unscoped{ self.receptor }).send_notification if change_record_category
      add_leave_days if Flow::LEAVE_TYPES.include?(self.type)
    end

    def add_leave_days
      self.leave_date_record.each do |month, leave_date_record|
        attendance_summary = self.receptor.attendance_summaries.find_by(summary_date: month)

        if leave_date_record && attendance_summary && !attendance_summary.attendance_summary_status_manager.department_hr_checked
          AttendanceCalculator.add_leave_days(
            {
              type: self.type,
              vacation_days: leave_date_record["vacation_days"],
              start_time: leave_date_record["start_time"],
              end_time: leave_date_record["end_time"]
            },
            self.receptor,
            attendance_summary
          )
        end
      end
    end

    def can_change_flow_type?
      self.errors.add(:error, "只支持请假流程修改假别") unless Flow::LEAVE_TYPES.include?(self.type)
    end

    def can_deduct?
      !(self.vacation_days =~ /-/)
    end

    def t_current_state
      I18n.t("flow.state.#{self.workflow_state}")
    end

    def serialized_form_data
      self.class::ATTRIBUTES.inject([]) do |form_data, key|
        if self.class.respond_to?(:filter_render_params) && self.class.filter_render_params.include?(key)
          form_data = form_data
        else
          value = parse_value(key)
          form_data << Hash[:name, I18n.t("flow.#{self.class}.form_data.#{key}"), :value, value]
        end
      end
    end

    def parse_value(key)
      return nil if !self.try(key).present?

      value = self.send(key)

      return value if (key =~ /(date|time)/).blank? or (key =~ /duration_date/).present?
      return Date.parse(value).to_s(:db) if Time.parse(value).strftime("%H:%M:%S") == "00:00:00"
      return Time.parse(value).strftime("%Y-%m-%d %H:%M:%S")
    end

    def set_leave_params
      self.start_leave_date = self.start_time
      self.end_leave_date = self.end_time || self.start_time
      self.start_time = self.start_time.sub("T00:00:00", "T#{Setting.daily_working_hours.morning}")
      self.end_time = self.end_time.sub("T00:00:00", "T#{Setting.daily_working_hours.afternoon_end}")

      leave_duration = Range.new(self.start_leave_date.month, self.end_leave_date.month).to_a
      start_time_str = self.start_leave_date.strftime("%Y-%m")
      end_time_str = self.end_leave_date.strftime("%Y-%m")
      leave_duration = [start_time_str]
      i = 1
      while leave_duration.last != end_time_str
        leave_duration << self.start_leave_date.advance(months: i).strftime("%Y-%m")
        i += 1
      end

      leave_date_record = leave_duration.inject({}) do |record, month|
        if self.start_leave_date.strftime("%Y-%m") == month
          if self.form_data["start_time"] =~ /\+08:00$/
            start_time = self.form_data["start_time"].sub("T00:00:00", "T#{Setting.daily_working_hours.morning}")
          else
            start_time = DateTime.iso8601(self.form_data["start_time"] + "T#{Setting.daily_working_hours.morning}+08:00")
          end
        else
          plus_month = leave_duration.index(month)
          start_time = DateTime.iso8601(self.start_leave_date.advance(months: plus_month).beginning_of_month.to_s + "T#{Setting.daily_working_hours.morning}+08:00")
        end

        if self.end_leave_date.strftime("%Y-%m") == month
          if self.form_data["end_time"] =~ /\+08:00$/
            end_time = self.form_data["end_time"].sub("T00:00:00", "T#{Setting.daily_working_hours.afternoon_end}")
          else
            end_time = DateTime.iso8601(self.form_data["end_time"] + "T#{Setting.daily_working_hours.afternoon_end}+08:00")
          end
        else
          plus_month = leave_duration.index(month)
          end_time = DateTime.iso8601(self.start_leave_date.advance(months: plus_month).end_of_month.to_s + "T#{Setting.daily_working_hours.afternoon_end}+08:00")
        end

        vacation_days = self.cal_vacation_days(start_time, end_time, I18n.t("flow.type.#{self.type}"))
        record[month] = {"start_time" => start_time.to_s, "end_time" => end_time.to_s, "leave_type" => self.type, "vacation_days" => vacation_days}
        record
      end

      self.leave_date_record = leave_date_record
      self.deduct_leave_date = {}
    end

    private
    def change_record_category
      if self.type == 'Flow::EmployeeLeaveJob' && self.reason == '工作调动'
        return 'employee_outgo'
      else
        return {
          "Flow::Resignation" => 'employee_resign',
          "Flow::Dismiss" => 'employee_fire',
          "Flow::Retirement" => 'employee_retire',
          "Flow::EarlyRetirement" => 'employee_early_retire'
        }[self.type]
      end
    end
  end
end

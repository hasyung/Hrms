class CreateFlowService
  def initialize(service_params)
    @flow_type    = service_params[:flow_type]
    @current_user = service_params[:current_user]
    @reviewer_ids = service_params[:reviewer_ids]
    @flow = build_flow(service_params[:flow_params])
    @errors = ''
    set_leave_params if Flow::LEAVE_TYPES.include?(@flow.type)
  end

  def call
    @flow.reviewer_ids = @reviewer_ids
    @flow.viewer_ids |= [@flow.receptor_id]
    @flow.viewer_ids |= [@flow.sponsor_id]
    @flow.viewer_ids = @flow.viewer_ids.uniq
    @flow.save!
    notice_reviewers
    @flow
  end

  def valid?
    if Flow::LEAVE_TYPES.include?(@flow.type)
      if "Flow::AnnualLeave" == @flow.type
        @flow.valid? && valid_leave_date_overlap && valid_annual_leave
      else
        @flow.valid? && valid_leave_date_overlap
      end
    else
      @flow.valid?
    end
  end

  def error_messages
    @flow.errors.values.flatten.join(",") + @errors
  end

  private
  def flow_klass
    "#{@flow_type}".constantize
  end

  def update_reviewers
    @flow.reviewer_ids = @reviewer_ids.uniq
    @flow.viewer_ids = [@flow.receptor_id]
    @flow.save
  end

  def notice_reviewers
    @flow.reviewer_ids.flatten.each do |employee_id|
      # Notification.send_workflow_messages(employee_id, @flow.type) unless Employee.find_by(id: employee_id).blank?
    end
  end

  def build_flow(flow_params)
    attachment_ids = flow_params.delete('attachment_ids')
    build_attributes = flow_params.merge!(sponsor_id: @current_user.id)

    flow = flow_klass.new(build_attributes)
    attachment_ids.each do |id|
      attachment = FlowAttachment.find_by(id: id)
      flow.flow_attachments << attachment if attachment
    end if attachment_ids.present?
    flow
  end

  def valid_annual_leave
    result = true
    demarcation_time = DateTime.parse("#{Date.today.year}-07-01T#{Setting.daily_working_hours.morning}+08:00")

    if VacationRecord.get_last_year_days(@flow.receptor_id) > 0 && @flow.end_time > demarcation_time && @flow.start_time < demarcation_time
      @errors = "去年年假有剩余，不能用于年假交割日期之后"
      return false
    end
    result
  end

  def valid_leave_date_overlap
    result = true
    months = @flow.leave_date_record.keys
    sql = "workflow_state not in ('repeal', 'rejected') AND " + months.inject("(") do |sql_str, month|
      if months.last != month
        sql_str += "leave_date_record like '%#{month}%' OR deduct_leave_date like '%#{month}%' OR "
      else
        sql_str += "leave_date_record like '%#{month}%' OR deduct_leave_date like '%#{month}%')"
      end
      sql_str
    end

    leave_duration = Range.new(@flow.start_time.to_date, @flow.end_time.to_date).to_a

    unless @flow.receptor.attendances.where("record_date in (?) AND record_type not like ?", leave_duration, "%删除%").empty?
      @errors = "该请假单与考勤的时间重合"
      return false
    end

    flows = @flow.receptor.own_flows.where(sql)
    return true if flows.empty?
    flows.each do |flow|
      prev_leave_duration = Range.new(flow.start_time.to_date, flow.end_time.to_date).to_a
      diff = leave_duration & prev_leave_duration

      if diff.count > 1
        result = false
        @errors = "该请假单与其他请假单的时间重合"
        break
      end

      if diff.count == 1
        unless (flow.start_time == @flow.end_time || flow.end_time == @flow.start_time)
          result = false
          @errors = "该请假单与其他请假单的时间重合"
          break
        end
      end
    end

    return result
  end

  def set_leave_params
    @flow.start_leave_date = @flow.start_time
    @flow.end_leave_date = @flow.end_time || @flow.start_time
    @flow.start_time = @flow.start_time.sub("T00:00:00", "T#{Setting.daily_working_hours.morning}")
    @flow.end_time = @flow.end_time.sub("T00:00:00", "T#{Setting.daily_working_hours.afternoon_end}")

    # leave_duration = Range.new(@flow.start_leave_date.month, @flow.end_leave_date.month).to_a
    start_time_str = @flow.start_leave_date.strftime("%Y-%m")
    end_time_str = @flow.end_leave_date.strftime("%Y-%m")
    leave_duration = [start_time_str]
    i = 1
    while leave_duration.last != end_time_str
      leave_duration << @flow.start_leave_date.advance(months: i).strftime("%Y-%m")
      i += 1
    end

    leave_date_record = leave_duration.inject({}) do |record, month|
      if @flow.start_leave_date.strftime("%Y-%m") == month
        if @flow.form_data["start_time"] =~ /\+08:00$/
          start_time = @flow.form_data["start_time"].sub("T00:00:00", "T#{Setting.daily_working_hours.morning}")
        else
          if @flow.form_data["start_time"].include?(Setting.daily_working_hours.afternoon)
            start_time = DateTime.iso8601(@flow.form_data["start_time"].to_date.to_s + "T#{Setting.daily_working_hours.afternoon}+08:00")
          else
            start_time = DateTime.iso8601(@flow.form_data["start_time"].to_date.to_s + "T#{Setting.daily_working_hours.morning}+08:00")
          end
          
        end
      else
        plus_month = leave_duration.index(month)
        start_time = DateTime.iso8601(@flow.start_leave_date.advance(months: plus_month).beginning_of_month.to_s + "T#{Setting.daily_working_hours.morning}+08:00")
      end

      if @flow.end_leave_date.strftime("%Y-%m") == month
        if @flow.form_data["end_time"] =~ /\+08:00$/
          end_time = @flow.form_data["end_time"].sub("T00:00:00", "T#{Setting.daily_working_hours.afternoon_end}")
        else
          if @flow.form_data["end_time"].include?(Setting.daily_working_hours.afternoon)
            end_time = DateTime.iso8601(@flow.form_data["end_time"].to_date.to_s + "T#{Setting.daily_working_hours.afternoon}+08:00")
          else
            end_time = DateTime.iso8601(@flow.form_data["end_time"].to_date.to_s + "T#{Setting.daily_working_hours.afternoon_end}+08:00")
          end
        end
      else
        plus_month = leave_duration.index(month)
        end_time = DateTime.iso8601(@flow.start_leave_date.advance(months: plus_month).end_of_month.to_s + "T#{Setting.daily_working_hours.afternoon_end}+08:00")
      end

      work_shifts = Employee.find_by(id:@flow.receptor_id).work_shifts.where(end_time: nil).first.try(:work_shifts)

      vacation_days = @flow.cal_vacation_days(start_time, end_time, I18n.t("flow.type.#{@flow.type}"), work_shifts)
      record[month] = {"start_time" => start_time.to_s, "end_time" => end_time.to_s, "leave_type" => @flow.type, "vacation_days" => vacation_days}
      record
    end

    @flow.leave_date_record = leave_date_record
    @flow.deduct_leave_date = {}
  end
end

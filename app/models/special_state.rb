class SpecialState < ActiveRecord::Base
  belongs_to :employee

  after_create :add_dinner_change
  after_update :update_dinner_change

  # 中期派驻? 30D
  def is_metaphase_send?
    days = (self.special_date_to - self.special_date_from).to_i + 1
    days >= 30 && days < 90
  end

  # 长期派驻? 90D
  def is_long_send?
    days = (self.special_date_to - self.special_date_from).to_i + 1
    days >= 90
  end

  def add_dinner_change
    if self.special_date_to.blank? || Date.has_natural_month?(self.special_date_to, self.special_date_from)
      hash = nil
      # 添加工作餐变动信息
      case self.special_category
      when "派驻"
        if self.special_date_to.present?
          change_date = self.special_date_to.prev_day < Date.current ? Date.current : self.special_date_to.prev_day
          hash2 = {employee_id: self.employee_id, category: '长期派驻回归', point: self.special_location,
            start_date: self.special_date_from, end_date: self.special_date_to, change_date: change_date}
          Publisher.broadcast_event('DINNER_CHANGE', hash2)
        end

        hash1 = {employee_id: self.employee_id, category: '长期派驻', point: self.special_location,
          start_date: self.special_date_from, end_date: self.special_date_to}
        Publisher.broadcast_event('DINNER_CHANGE', hash1)
      when "空勤停飞"
        hash = {employee_id: self.employee_id, category: '空勤停飞', start_date: self.special_date_from,
          end_date: self.special_date_to}
        Publisher.broadcast_event('DINNER_CHANGE', hash)
      when "借调"
        if self.special_date_to.present?
          change_date = self.special_date_to.prev_day < Date.current ? Date.current : self.special_date_to.prev_day
          hash2 = {employee_id: self.employee_id, category: '人员借调回归', point: self.special_location,
            start_date: self.special_date_from, end_date: self.special_date_to, change_date: change_date}
          Publisher.broadcast_event('DINNER_CHANGE', hash2)
        end

        hash1 = {employee_id: self.employee_id, category: '人员借调', point: self.special_location,
          start_date: self.special_date_from, end_date: self.special_date_to}
        Publisher.broadcast_event('DINNER_CHANGE', hash1)
      when "离岗培训"
        hash = {employee_id: self.employee_id, category: '离岗培训', start_date: self.special_date_from,
          end_date: self.special_date_to}
        Publisher.broadcast_event('DINNER_CHANGE', hash)
      else

      end
    end
  end

  def update_dinner_change
    if self.special_date_to.present? && self.special_date_to_was == nil && Date.has_natural_month?(self.special_date_to, self.special_date_from)
      change_date = self.special_date_to.prev_day < Date.current ? Date.current : self.special_date_to.prev_day
      if self.special_category == "派驻"
        hash = {employee_id: self.employee_id, category: '长期派驻回归', point: self.special_location,
          start_date: self.special_date_from, end_date: self.special_date_to, change_date: change_date}
        Publisher.broadcast_event('DINNER_CHANGE', hash)
      end
      if self.special_category == "借调"
        hash = {employee_id: self.employee_id, category: '人员借调回归', point: self.special_location,
          start_date: self.special_date_from, end_date: self.special_date_to, change_date: change_date}
        Publisher.broadcast_event('DINNER_CHANGE', hash)
      end
    end
  end

  def summary_cultivate
    #培训记录考勤汇总
    cultivate_days = Range.new(self.special_date_from, self.special_date_to)
      .group_by{|day| day.strftime("%Y-%m")}
      .inject({}){|result, (key, val)| result[key] = val.count; result}

    cultivate_days.each do |summary_date, days|
      attendance_summary = self.employee.attendance_summaries.find_by(summary_date: summary_date)

      if attendance_summary
        AttendanceCalculator.add_leave_days({type: 'cultivate', vacation_days: days}, self.employee, attendance_summary)
      end
    end
  end

  def not_full_months(month)
    standard_start = (month + '-01').to_date
    standard_end = (month + '-01').to_date.end_of_month

    return 0 if (self.special_date_to.present? && self.special_date_to < standard_start) || self.special_date_from > standard_end

    Date.difference_in_months(self.special_date_to || standard_start, self.special_date_from)
  end

  def is_in_month?(month)
    standard_start = (month + '-01').to_date
    standard_end = (month + '-01').to_date.end_of_month

    if (self.special_date_to.present? && self.special_date_to < standard_start) || self.special_date_from > standard_end
      return false
    else
      return true
    end
  end

  def to_flow_record(month)
    start_date = "#{month}-01".to_date
    end_date = start_date.end_of_month

    return nil if self.special_date_from > end_date or (self.special_date_to.present? and self.special_date_to < start_date)
    standard_start = self.special_date_from < start_date ? start_date : self.special_date_from
    standard_end = (self.special_date_to.blank? or self.special_date_to > end_date) ? end_date : self.special_date_to
    start_time = standard_start.to_s + "T#{Setting.daily_working_hours.morning}+08:00"
    end_time = standard_end.to_s + "T#{Setting.daily_working_hours.afternoon_end}+08:00"
    
    {
      "start_time" => start_time,
      "end_time" => end_time,
      "leave_type" => "SpecialState::ground",
      "vacation_days" => VacationRecord.cals_days(
          employee_id: self.employee_id,
          start_time: start_time.to_datetime,
          end_time: end_time.to_datetime,
          start_date: start_time.to_date,
          end_date: end_time.to_date,
          vacation_type: I18n.t("flow.type.Flow::SickLeave"),
          is_contain_free_day: true
        )[:vacation_days]
    }
  end

  class << self
    def personal_stop_fly_months(special_states, month)
      special_states = special_states.select{|s| s.stop_fly_reason == '个人原因'}
      stop_fly_months(special_states, month)
    end

    def stop_fly_months(special_states, month)
      standard_end = (month + '-01').to_date.end_of_month
      long_times = special_states.select{|s| s.special_date_to.blank?}
      sure_times = special_states.select{|s| s.special_date_to.present? && s.special_date_to >= standard_end}

      return 0 if long_times.blank? && sure_times.blank?

      long_start = long_times.first.try(:special_date_from)
      sure_start = sure_times.first.try(:special_date_from)

      sure_times.delete(sure_times.first)
      sure_times.each do |time|
        break if sure_start.prev_day > time.special_date_to
        sure_start = time.special_date_from
      end

      standard_start = nil
      if long_start.present? && sure_start.present?
        standard_start = long_start > sure_start ? sure_start : long_start
      else
        standard_start = long_start || sure_start
      end

      Date.difference_in_months(standard_end, standard_start)
    end

    #计算当月此人某种类型的天数
    def in_month_special_days(employee_special_state, month, type)
      sum_days = 0
      start_month = (month + "-01").to_date
      end_month = (month + "-01").to_date.end_of_month
      employee_special_state.select{|special| special.is_in_month?(month) && special.special_category == type}.each do |special_state|
        if special_state.special_date_to.present? && special_state.special_date_from < start_month
          sum_days = sum_days + Range.new(start_month, special_state.special_date_to).to_a.size
        elsif special_state.special_date_to.blank? || special_state.special_date_to > end_month
          sum_days = sum_days + Range.new(special_state.special_date_from, end_month).to_a.size
        elsif special_state.special_date_to.present? && special_state.special_date_from >= start_month && special_state.special_date_to <= end_month
          sum_days = sum_days + Range.new(special_state.special_date_from, special_state.special_date_to).to_a.size
        end
      end
      sum_days
    end
  end

end

# 事假，病假（病假，病假工伤待定，病假怀孕待产）
# 这几种假需要从它们的天数中提取出工作日的天数
# 进行存储

class AttendanceSummary < ActiveRecord::Base
  belongs_to :employee
  belongs_to :attendance_summary_status_manager

  # validates :family_planning_leave, :recuperate_leave, :station_days, :format => { :with => /\A\d+??(?:\.5)?\z/,
  #   message: '参数只能填写数字，小数点最多表示0.5' }

  before_update :summary_paid_leave

  SPECIALSTATETYPE = {
    '驻站天数' => 'station_days',
    '离岗培训' => 'cultivate',
    '出差' => 'evection',
    '空勤停飞' => 'ground',
    '空勤地面' => 'surface_work',
    '派驻' => 'accredit_leave',
    'work_days' => {
      '驻站天数' => 'station_days',
      '离岗培训' => 'cultivate_work_days',
      '出差' => 'evection_work_days',
      '空勤停飞' => 'ground_work_days',
      '空勤地面' => 'surface_work_days'
    }
  }

  class << self
    # 员工department_id变化后修正员工的考勤汇总数据
    def update_summary(employees, summary_date = Date.today.strftime("%Y-%m"))
      employees.each do |employee|
        attendance_summary = employee.attendance_summaries.find_by(summary_date: summary_date)

        if attendance_summary.try(:attendance_summary_status_manager) && !attendance_summary.try(:attendance_summary_status_manager).try(:department_hr_checked)
          original_department_root_id = Department.find(attendance_summary.department_id).parent_chain.first
          new_department_root_id = employee.department.parent_chain.first

          if original_department_root_id != new_department_root_id
            attendance_summary_status_manager_id = AttendanceSummaryStatusManager.find_by(summary_date: summary_date, department_id: new_department_root_id).id
            attendance_summary.update(attendance_summary_status_manager_id: attendance_summary_status_manager_id)
          end
          attendance_summary.update(department_id: employee.department_id, department_name: employee.department.full_name)
        end
      end
    end

    # 检查某月的考勤数据状态是否满足计算薪酬的条件
    # 目前的条件只有: 考勤是否被确认
    # 返回 false, messages
    def can_calc_salary?(month)
      return [true, "考勤数据已确认"] if Rails.env.test?

      if AttendanceSummaryStatusManager.where(summary_date: month).select{|a| a unless a.hr_department_leader_checked}.count > 0
        return [false, "考勤数据还未确认"]
      else
        return [true, "考勤数据已确认"]
      end
    end

    def get_attendance_type_days_by_vacation(employee, month, past_months)
      summary_dates = get_summary_dates(month, past_months)
      attendance_summaries = employee.attendance_summaries.where(summary_date: summary_dates)
      calculator_items = %w(annual_leave sick_leave sick_leave_injury sick_leave_nulliparous personal_leave home_leave paid_leave)

      attendance_summaries.inject(0) do |days, attendance_summary|
        month_days = calculator_items.inject(0){|result, method_name| result = eval("#{result} + #{attendance_summary.send(method_name)}"); result}

        if attendance_summary.annual_leave.to_f != 0 || attendance_summary.accredit_leave != 0
          summary_date = attendance_summary.summary_date
          start_date = Date.parse(summary_date + '-01')
          free_days = VacationRecord.check_free_days(start_date, start_date.end_of_month)
          flows = employee.own_flows.where("(leave_date_record like ? OR deduct_leave_date like ?) AND workflow_state = 'actived'", "%#{summary_date}%", "%#{summary_date}%")
          leave_records = flows.pluck(:leave_date_record).map{|record| record[summary_date]}.compact
          deduct_records = flows.pluck(:deduct_leave_date).map{|record| record[summary_date]}.compact
          leave_days = (leave_records + deduct_records)
            .select{|record| Flow::WORKING_DAYS_LEAVE_FLOW.include?(record["leave_type"])}
            .compact
            .inject([]){|days, record| days << Range.new(record["start_time"].to_date, record["end_time"].to_date).to_a; days}
            .flatten

          month_days += (free_days & leave_days).count
        end

        days += month_days
        days
      end
    end

    def get_attendance_type_days_by_leave_position(employee, month, past_months)
      summary_dates = get_summary_dates(month, past_months)
      attendance_summaries = employee.attendance_summaries.where(summary_date: summary_dates)

      attendance_summaries.inject(0) do |days, attendance_summary|
        days = eval("#{days} + #{attendance_summary.cultivate}")
        days
      end
    end

    def get_attendance_type_days_by_business_trip(employee, month, past_months)
      summary_dates = get_summary_dates(month, past_months)
      attendance_summaries = employee.attendance_summaries.where(summary_date: summary_dates)

      attendance_summaries.inject(0) do |days, attendance_summary|
        days = eval("#{days} + #{attendance_summary.evection}")
        days
      end
    end

    private
    def get_summary_dates(month, past_months)
      month = Date.parse(month + "-01")
      summary_dates = (0..past_months).inject([]){|result, i| result << month.advance(months: -i); result}.map{|i| i.strftime("%Y-%m")}
    end
  end

  def can_summary?
    self.attendance_summary_status_manager.department_hr_checked != true
  end

  # 获取相应假别扣除自然日后, 前段自然日天数、后段工作日天数
  # natural_days: 扣除自然日天数
  # type_index = 1, 标识假别类型，包含事假(personal_leave)和病假(sick_leave/sick_leave_injury/sick_leave_nulliparous)和空勤停飞(ground)
  # type_index = 2, 标识假别类型，包含事假(personal_leave)和探亲假(home_leave)和病假(sick_leave/sick_leave_injury/sick_leave_nulliparous)
  #
  # leave_index = 1, 病假(sick_leave/sick_leave_injury/sick_leave_nulliparous)和空勤停飞(ground)
  # leave_index = 2, 事假(personal_leave)
  # leave_index = 3, 探亲假(home_leave)
  def get_residue_work_days(type_index, leave_index, natural_days = 5, special_states = nil)
    # 假设扣除的自然日天数为5，则数组第一个值为前5天自然日里包含的相应假别的自然日，第二个值为扣除5天后剩余的相应假别的工作日
    original_days = 0
    work_days = 0
    query_types = get_type_by_index(type_index)
    leave_counters = get_leave_by_index(leave_index)
    records = self.employee.own_flows.where("leave_date_record like ? AND workflow_state = 'actived'", "%#{self.summary_date}%")
      .pluck(:leave_date_record).map{|record| record[self.summary_date]}
      .compact
      .select{ |record| query_types.include?(record["leave_type"]) }

    states = special_states.inject([]) do |arr, s|
      flow = s.to_flow_record(self.summary_date)
      arr << flow if flow
      arr
    end unless special_states.blank?

    records = records + states unless states.blank?
    records = records.sort{ |prev, current| prev["start_time"].to_date <=> current["start_time"].to_date }


    return [original_days, work_days] if records.blank?

    while natural_days > 0 && !records.blank?
      record = records.first

      if leave_counters.include?(record["leave_type"])
        if record["vacation_days"] > natural_days
          original_days += natural_days
          start_time = record["start_time"].to_datetime.advance(days: natural_days).to_s
          record["start_time"] = start_time.sub("T01:00:00", "T#{Setting.daily_working_hours.morning}").sub("T21:00:00", "T#{Setting.daily_working_hours.afternoon}")
          record["vacation_days"] -= natural_days
          natural_days = 0
        else
          original_days += record["vacation_days"]
          natural_days -= record["vacation_days"]
          records.shift
        end
      else
        natural_days -= record["vacation_days"]
        records.shift
      end
    end

    start_date = Date.parse("#{self.summary_date}-01")
    free_days = VacationRecord.check_free_days(start_date, start_date.end_of_month)
    records.each do |record|
      if leave_counters.include?(record["leave_type"])
        leave_days = Range.new(record["start_time"].to_date, record["end_time"].to_date).to_a
        working_days = (leave_days - free_days)

        working_days.each do |day|
          if (record["start_time"].to_date == day && record["start_time"].include?("T#{Setting.daily_working_hours.afternoon}")) || (record["end_time"].to_date == day && record["end_time"].include?("T#{Setting.daily_working_hours.afternoon}"))
            work_days += 0.5
          else
            work_days += 1
          end
        end
      end
    end

    [original_days, work_days]
  end

  # 在汇总时将异动的天数写入汇总表里面
  def self.special_state_days_to_summaries summary_date, flow_relation_id, check_hr, department_id
    attendance_summary_status_manager = AttendanceSummaryStatusManager.find_by(summary_date: summary_date.to_date.strftime("%Y-%m"), department_id: department_id)
    return if attendance_summary_status_manager.nil? || attendance_summary_status_manager.department_hr_checked
    original_total_days = 0
    work_days = 0
    SpecialState.all.each do |special_state|
      next if  special_state.special_date_from.to_date > summary_date.to_date.end_of_month
      next if special_state.special_category == "借调"
      if check_hr
        begin
          next if Department.find_by(id:Employee.find_by(id:special_state.employee_id).department_id).parent_chain.map!{|department|department.id}.find_index(flow_relation_id).nil?
        rescue Exception => e
          next
        end
      else
        begin
          next unless Department.find_by(id:Employee.find_by(id:special_state.employee_id).department_id).parent_chain.map!{|department|department.id}.first == department_id
        rescue
          next
        end
      end
    
      # 对没有结束日期的进行处理
      if special_state.special_date_to.nil?
        unless AttendanceSummary.find_by(employee_id:special_state.employee_id, summary_date:summary_date.to_date.strftime("%Y-%m")).nil?
          if special_state.special_date_from.to_date < summary_date.to_date.beginning_of_month
            original_total_days = (summary_date.to_date.end_of_month - summary_date.to_date.beginning_of_month).to_i + 1
            work_days = original_total_days - VacationRecord.check_free_days(summary_date.to_date.beginning_of_month, summary_date.to_date.end_of_month).size
          else
            original_total_days = (summary_date.to_date.end_of_month - special_state.special_date_from.to_date).to_i + 1
            work_days = original_total_days - VacationRecord.check_free_days(special_state.special_date_from.to_date, summary_date.to_date.end_of_month).size
          end
          attendance_summary = AttendanceSummary.find_by(employee_id:special_state.employee_id, summary_date:summary_date.to_date.strftime("%Y-%m").to_s)
          attendance_summary.send("#{SPECIALSTATETYPE[special_state.special_category]}=",attendance_summary.send("#{SPECIALSTATETYPE[special_state.special_category]}").to_i + original_total_days) 
          if special_state.special_category != "派驻"
            attendance_summary.send("#{SPECIALSTATETYPE['work_days'][special_state.special_category]}=",attendance_summary.send("#{SPECIALSTATETYPE['work_days'][special_state.special_category]}").to_i + work_days)
          elsif special_state.special_category == "派驻"
            if attendance_summary.station_place.nil? || attendance_summary.station_place == ""
              attendance_summary.station_place = special_state.special_location
            else
              attendance_summary.station_place = attendance_summary.station_place + ",#{special_state.special_location}"
            end
          end
          attendance_summary.save
        end
      end

      if !special_state.special_date_to.nil? && special_state.special_date_to.to_date >= summary_date.to_date.beginning_of_month && special_state.special_date_to.to_date <= summary_date.to_date.end_of_month
        unless AttendanceSummary.find_by(employee_id:special_state.employee_id, summary_date:summary_date.to_date.strftime("%Y-%m").to_s).nil?
          if special_state.special_date_from.to_date < summary_date.to_date.beginning_of_month
            original_total_days = (special_state.special_date_to.to_date - summary_date.to_date.beginning_of_month).to_i + 1
            work_days = original_total_days - VacationRecord.check_free_days(summary_date.to_date.beginning_of_month, special_state.special_date_to.to_date).size
          else
            original_total_days = (special_state.special_date_to.to_date. - special_state.special_date_from.to_date).to_i + 1
            work_days = original_total_days - VacationRecord.check_free_days(special_state.special_date_from.to_date, special_state.special_date_to.to_date).size
          end
          attendance_summary = AttendanceSummary.find_by(employee_id:special_state.employee_id, summary_date:summary_date.to_date.strftime("%Y-%m").to_s)
          attendance_summary.send("#{SPECIALSTATETYPE[special_state.special_category]}=",attendance_summary.send("#{SPECIALSTATETYPE[special_state.special_category]}").to_i + original_total_days) 
          if special_state.special_category != "派驻"
            attendance_summary.send("#{SPECIALSTATETYPE['work_days'][special_state.special_category]}=",attendance_summary.send("#{SPECIALSTATETYPE['work_days'][special_state.special_category]}").to_i + work_days)
          elsif special_state.special_category == "派驻"
            if attendance_summary.station_place.nil? || attendance_summary.station_place == ""
              attendance_summary.station_place = special_state.special_location
            else
              attendance_summary.station_place = attendance_summary.station_place + ",#{special_state.special_location}"
            end
          end
          attendance_summary.save
        end
      end

      if !special_state.special_date_to.nil? && special_state.special_date_to.to_date > summary_date.to_date.end_of_month
        unless AttendanceSummary.find_by(employee_id:special_state.employee_id, summary_date:summary_date.to_date.strftime("%Y-%m").to_s).nil?
          if special_state.special_date_from.to_date < summary_date.to_date.beginning_of_month
            original_total_days = (summary_date.to_date.end_of_month - summary_date.to_date.beginning_of_month).to_i + 1
            work_days = original_total_days - VacationRecord.check_free_days(summary_date.to_date.beginning_of_month,summary_date.to_date.end_of_month).size
          else
            original_total_days = (summary_date.to_date.end_of_month. - special_state.special_date_from.to_date).to_i + 1
            work_days = original_total_days - VacationRecord.check_free_days(special_state.special_date_from.to_date, summary_date.to_date.end_of_month).size
          end
          attendance_summary = AttendanceSummary.find_by(employee_id:special_state.employee_id, summary_date:summary_date.to_date.strftime("%Y-%m").to_s)
          attendance_summary.send("#{SPECIALSTATETYPE[special_state.special_category]}=",attendance_summary.send("#{SPECIALSTATETYPE[special_state.special_category]}").to_i + original_total_days) 
          if special_state.special_category != "派驻"
            attendance_summary.send("#{SPECIALSTATETYPE['work_days'][special_state.special_category]}=",attendance_summary.send("#{SPECIALSTATETYPE['work_days'][special_state.special_category]}").to_i + work_days)
          elsif special_state.special_category == "派驻" || attendance_summary.station_place == ""
            if attendance_summary.station_place.nil?
              attendance_summary.station_place = special_state.special_location
            else
              attendance_summary.station_place = attendance_summary.station_place + ",#{special_state.special_location}"
            end
          end
          attendance_summary.save
        end
      end
    end
  end

  private
  def get_type_by_index(index)
    {
      1 => ["Flow::PersonalLeave", "Flow::SickLeave", "Flow::SickLeaveInjury", "Flow::SickLeaveNulliparous", "SpecialState::ground"],
      2 => ["Flow::PersonalLeave", "Flow::SickLeave", "Flow::SickLeaveInjury", "Flow::SickLeaveNulliparous", "Flow::HomeLeave"]
    }[index]
  end

  def get_leave_by_index(index)
    {
      1 => ["Flow::SickLeave", "Flow::SickLeaveInjury", "Flow::SickLeaveNulliparous", "SpecialState::ground"],
      2 => ["Flow::PersonalLeave"],
      3 => ["Flow::HomeLeave"]
    }[index]
  end

  def summary_paid_leave
    paid_leaves = self.changed & %w(family_planning_leave recuperate_leave)

    unless paid_leaves.empty?
      paid_leaves.each do |field_name|
        self.paid_leave = eval("#{self.paid_leave} + #{self.send(field_name)}")
      end
    end
  end
end

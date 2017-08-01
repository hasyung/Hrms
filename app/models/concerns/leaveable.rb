module Leaveable
  extend ActiveSupport::Concern

  included do
    # type：新的请假类别
    # months: 需要调整的请假时段
    # 若为年，事，病假变为其他假需要判断恢复年假
    # 若其他假变为年，事，病假需要判断是否扣除年假
    def adjust_leave_type(type, months)
      records = self.leave_date_record
      ex_type = self.type
      attendance_summary = self.receptor.attendance_summaries.find_by(summary_date: Date.today.strftime("%Y-%m"))

      # 找出对应的时段修改他们的请假类别
      # 如果本月汇总确认之前调整了假别计算出对应的请假时长
      months.each do |month|
        record = records[month]
        work_days = self.cal_vacation_days(record["start_time"], record["end_time"], iname(type))
        record["vacation_days"] = work_days
        record["leave_type"] = type
      end

      # 需不需要更新form_date里面的vacation_days???
      self.update(leave_date_record: records)
      self.restore_reduce_days if reduce_leave_types?(self.type)
      form_data = self.form_data
      form_data["vacation_days"] = records.values.inject(0){|result, value| result += value["vacation_days"]; result}
      self.update(type: type, name: iname(type), is_adjusted: true, form_data: form_data)
      new_self = Flow.find(self.id)
      new_self.force_reduce_days if reduce_leave_types?(new_self.type)

      # 修改对应考勤汇总数据
      # 1. 汇总已经确认：
      # 当月时段的请假和之前假别相同，不做任何处理，证明这是在汇总确认之后更改了的；
      # 当月时段的请假和之前假别不同，需要减去之前假别的天数，给新的假别添加天数
      # 2. 汇总未确认：
      # 当月时段的请假和之前假别肯定会不同，需要减去之前假别的天数，给新的假别添加天数
      change_attendance_summary(attendance_summary, ex_type, new_self)
    end

    def reduce_leave_types?(type)
      %W(Flow::SickLeave Flow::AnnualLeave Flow::PersonalLeave).include?(type)
    end

    def cal_vacation_days(start_time, end_time, vacation_type, work_shifts = "行政班")
      start_time = start_time.to_datetime
      end_time = end_time.to_datetime
      results = VacationRecord.cals_days(
        employee_id: self.receptor_id,
        start_time: start_time,
        end_time: end_time,
        start_date: start_time.beginning_of_day.to_date,
        end_date: end_time.beginning_of_day.to_date,
        vacation_type: vacation_type,
        work_shifts: work_shifts || "行政班"
      )[:general_days]


    end

    private
    def change_attendance_summary(attendance_summary, ex_type, flow)
      record = flow.leave_date_record[attendance_summary.summary_date]

      unless ex_type == record["leave_type"]
        ex_vacation_days = cal_vacation_days(record["start_time"], record["end_time"], iname(ex_type))
        AttendanceCalculator.change_leave_days(
          {
            ex_type: ex_type,
            ex_vacation_days: ex_vacation_days,
            type: record["leave_type"],
            vacation_days: record["vacation_days"],
            start_time: record["start_time"],
            end_time: record["end_time"]
          },
          flow.receptor
        )
      end
    end

    def iname(type)
      I18n.t("flow.type.#{type}")
    end
  end
end

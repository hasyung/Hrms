## 调整假别逻辑
# 1. 考勤汇总已审核（部门HR已审核），且请假段在本月内的不可以进行假别修正
# 2. 考勤汇总已审核，但是存在夸月的情况，本月汇总了的数据不做修改；
#    在下个月的时候我们按照新的假别来重新计算请假天数
# 3. 如果可以进行假别更正，如果假别调整为年假，病假，事假，还需要
#    根据情况来进行年假的扣减；年假，病假，事假也可以更改为其他假别
#    我们需要对年假天数进行回滚
# 4. 已经抵扣和调整了的假别不能够再调整

class AdjustLeaveTypeService
  # 1. 员工新入职后需要创建相应的attendance_summary
  # 2. 员工调岗后需要修改attendance_summary中的department_id
  # 和 attendance_summary_status_manager_id
  def initialize(flow, type)
    @flow = flow
    @type = type
    @leave_duration = @flow.leave_date_record.keys
    @attendance_summaries = @flow.receptor.attendance_summaries
    @adjust_months = []
  end

  # 考勤汇总未确认或是汇总确认了但是存在跨月的可以进行修改
  def can_adjust?
    prediction = false

    @leave_duration.each_with_index do |month, index|
      attendance_summary = @attendance_summaries.find_by(summary_date: month)

      # 如果没有找到考勤记录，证明存在了跨月且没有汇总确认
      unless attendance_summary
        (prediction = true) and (@adjust_months = @leave_duration[index..-1]) and break
      end

      # 如果有部门HR没有汇总确认，那么一定有个时间段可以进行假别修正
      department_hr_checked = attendance_summary.attendance_summary_status_manager.department_hr_checked
      unless department_hr_checked
        (prediction = true) and (@adjust_months = @leave_duration[index..-1]) and break
      end
    end

    return prediction
  end

  def adjust
    # 1. 调整对应假别
    # 2. 对于出现事假，病假，年假这种有抵扣的需要进行相应抵扣
    @flow.adjust_leave_type(@type, @adjust_months)
  end
end 
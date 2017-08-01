class FutureTask
  # 请假生效
  def self.active_leave_flow
    flows = Flow.where(workflow_state: 'accepted', type: Flow::LEAVE_TYPES)

    flows.each do |flow|
      start_time = flow.start_time.to_datetime

      if DateTime.now > start_time
        flow.respond_to?(:active_job) ? flow.active_job : flow.active_workflow
      end
    end
  end

  # 生成主官的季度绩效考核
  def self.generate_season_performance
    season_month = [12, 3, 6, 9]
    date = Date.today
    assess_time = date.beginning_of_month
    year = (date.month == 12) ? (date.year + 1) : (date.year)

    return unless season_month.include?(date.month) && date == assess_time

    Employee.where(pcategory: '主官').each do |emp|
      Performance.create({
        employee_id: emp.id,
        employee_name: emp.name,
        employee_no: emp.employee_no,
        department_name: emp.department.full_name,
        position_name: emp.master_position.name,
        channel: emp.channel.try(:display_name),
        assess_time: assess_time,
        category: 'season',
        assess_year: year
      })
    end
  end

  # 每个月1号生成员工的考勤汇总
  def self.generate_attendance_summary
    if can_generate_attendance_summary?
      departments = Department.where(depth: 2)
      summary_date = Date.today.strftime("%Y-%m")

      departments.each do |department|
        attendance_summary_status_manager = AttendanceSummaryStatusManager.create(department_id: department.id, department_name: department.name, summary_date: summary_date)
        department_ids = Department.where('serial_number like ?', "#{department.serial_number}%").pluck(:id)

        AttendanceSummary.transaction do
          department_ids.each do |department_id|
            Employee.where(department_id: department_id).each do |employee|
              attendance_summary_status_manager.attendance_summaries.create!(
                employee_id: employee.id,
                employee_name: employee.name,
                employee_no: employee.employee_no,
                department_id: department_id,
                department_name: employee.department.full_name,
                labor_relation: employee.labor_relation.display_name, 
                summary_date: summary_date
              )
            end
          end
        end
      end

      # 查找出有跨月的流程，将它们写入本月的考勤汇总中去
      AttendanceSummary.transaction do 
        flows = Flow.where("workflow_state = 'actived' AND (leave_date_record like ? OR deduct_leave_date like ?)", "%#{summary_date}%", "%#{summary_date}%")

        flows.each do |flow|
          records = [flow.leave_date_record[summary_date], flow.deduct_leave_date[summary_date]].compact
          attendance_summary = flow.receptor.attendance_summaries.find_by(summary_date: summary_date)
          records.each do |record|
            AttendanceCalculator.add_leave_days(
              {
                type: record["leave_type"],
                vacation_days: record["vacation_days"],
                start_time: record["start_time"],
                end_time: record["end_time"]
              },
              flow.receptor,
              attendance_summary
            )
          end
        end
      end

      # 查找出本月有离岗培训的，并写入考勤汇总中去
      AttendanceSummary.transaction do
        special_states = SpecialState.where("special_category = ? AND special_date_from <= ? AND special_date_to >= ? ", "离岗培训", Date.today.end_of_month, Date.today.beginning_of_month)
        special_states.each do |state|
          state.summary_cultivate
        end
      end
    end
  end

  def self.can_generate_attendance_summary?
    (Date.today == Date.today.beginning_of_month) && \
    AttendanceSummaryStatusManager.where(summary_date: Date.today.strftime("%Y-%m")).empty?
  end

  # 飞行员档级变更检测
  def self.flyer_salary_grade_change
    channel_id = CodeTable::Channel.find_by(display_name: "飞行").id
    Employee.where(channel_id: channel_id).each do |emp|
    end
  end

  # 调岗定时检查
  def self.position_change_active
    PositionChangeRecord.where("position_change_date <=  ? and is_finished = ?" ,Date.today, false).each do |record|
      Audited.audit_class.as_user(Employee.unscoped.find(record.operator_id)) do
        record.active_change!
      end
    end
  end

  def self.technical_grade_change_active
    #定时任务，触发调整员工技术通道变更
    TechnicalGradeChangeRecord.where(status: false).each do |item|
      item.active_change
    end
  end

  def self.clear_crono_job_logs
    CronoJob.first.update(log: nil)
  end

  def perform
    PushWebTask.notify_alls
    FutureTask.generate_season_performance
    FutureTask.generate_attendance_summary
    FutureTask.position_change_active
    FutureTask.technical_grade_change_active
    FutureTask.active_leave_flow
    FutureTask.clear_crono_job_logs

  end
end

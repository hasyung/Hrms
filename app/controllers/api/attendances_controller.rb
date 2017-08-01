class Api::AttendancesController < ApplicationController
  include ExceptionHandler

  def index
    result = parse_query_params!('attendance')
    render json: {messages: result[:error]}, status: 400 and return unless result[:error].blank?

    relations, conditions, sorts, page = result.values

    # @attendances = Attendance.includes(
    # :employee => [:job_title_degree, :job_title, :gender, :political_status, :nation,
    #               :education_background, :contact, :master_positions,
    #               :category, :labor_relation, :channel,
    #               :positions => [:department]]).joins(relations).order(sorts)

    # 会生成INNER JOIN，查询丢左表
    # @attendances = Attendance.joins(
    # :employee => [:job_title_degree, :job_title, :gender, :political_status, :nation,
    #               :education_background, :contact, :master_positions,
    #               :category, :labor_relation, :channel,
    #               :positions => [:department]]).joins(relations).order(sorts)

    @attendances = Employee.full_join(Attendance).joins(relations).order('attendances.record_date desc').order(sorts)

    if !@current_employee.hr_labor_relation_member?
      department_ids = @current_employee.get_departments_for_role
      if department_ids.present?
        @attendances = @attendances.where("positions.department_id in (?) or attendances.employee_id = #{@current_employee.id}", department_ids)
      else
        @attendances = @attendances.where("attendances.employee_id = #{@current_employee.id}")
      end
    end

    conditions.each do |condition|
      @attendances = @attendances.where(condition)
    end

    @attendances = set_page_meta @attendances, page
  end

  def employees
    render text: ''
  end

  def history
    render text: ''
  end

  def approve
    render text: ''
  end

  def leave_list
    render text: ''
  end

  def summary
    render text: ''
  end

  def summary_history
    render text: ''
  end

  def create
    data = attendance_params
    @employee = Employee.find(data[:employee_id])

    render json: {messages: "员工在该日期存在请假或考勤记录"}, status: 400 and return unless can_add_attendance?(data)
    render json: {messages: "部门HR已经汇总确认本月不能再添加考勤"}, status: 400 and return unless can_attendance?(@employee, data[:record_date].to_date)  

    @attendance = Attendance.new(data)

    if @attendance.save
      render json: {}
    else
      render json: {messages: @attendance.errors.values.flatten.join(",")}
    end
  end

  def update
    @attendance = Attendance.find(params[:id])

    render json: {messages: "部门HR已经汇总确认本月不能再修改考勤"}, status: 400 and return unless can_attendance?(@attendance.employee, @attendance.record_date)  
    render json: {messages: "该考勤记录已标记为删除"}, status: 400 and return if @attendance.is_delete

    @attendance.update_type(attendance_params[:record_type])
    render template: '/api/attendances/show'
  end

  def destroy
    @attendance = Attendance.find(params[:id])

    render json: {messages: "部门HR已经汇总确认本月不能再删除考勤"}, status: 400 and return unless can_attendance?(@attendance.employee, @attendance.record_date)  
    render json: {} and return if @attendance.is_delete

    @attendance.update_type("删除")
    render template: '/api/attendances/show'
  end

  private
  def attendance_params
    safe_params([:employee_id, :record_type, :record_date])
  end

  def can_attendance?(employee, record_date)
    status_manager = employee.attendance_summaries.find_by(summary_date: record_date.strftime("%Y-%m")).attendance_summary_status_manager

    status_manager.department_hr_checked ? false : true
  end

  def can_add_attendance?(data)
    #检测是否和请假记录重合
    employee = Employee.find(data[:employee_id])
    flows = employee.own_flows.where(type: Flow::LEAVE_TYPES)
    prediction = true
    flows.each do |flow|
      record_date = data[:record_date].to_date

      if flow.start_time.to_date <= record_date && record_date  <= flow.end_time.to_date
        prediction = false
        break
      end
    end
    if employee.attendances.find_by(record_date: data[:record_date].to_date)
      prediction = false
    end
    return prediction
  end
end

class Api::AttendanceSummariesController < ApplicationController
  include ExceptionHandler

  before_action :find_status_manager, only: [:department_hr_confirm]
  before_action :check_update_permission, only: [:update]
  skip_before_action :check_permission, only: [:attendance_summary_department_list]
  skip_before_action :check_action_register, only: [:attendance_summary_department_list]

  def department_hr_confirm
    return render json: {messages: '该月考勤汇总已经确认'}, status: 400 if @attendance_summary_status_manager.department_hr_checked
    
    @attendance_summary_status_manager.department_hr_check(@current_employee)
    @attendance_summary_status_manager.update_department_name

    render json: @attendance_summary_status_manager
  end

  def department_leader_check
    department_id = FlowRelation.get_department_leader_dep_id(@current_employee).first
    summary_date = params[:summary_date].to_date.strftime("%Y-%m")
    @attendance_summary_status_manager = AttendanceSummaryStatusManager.find_by(summary_date: summary_date, department_id: department_id)

    raise ActiveRecord::RecordNotFound if @attendance_summary_status_manager.nil?
    return render json: {messages: '该月考勤汇总部门HR还未审核'}, status: 400 if !@attendance_summary_status_manager.department_hr_checked
    return render json: {messages: '该月考勤汇总已经审核'}, status: 400 if @attendance_summary_status_manager.department_leader_checked

    @attendance_summary_status_manager.department_leader_check(@current_employee, params[:department_leader_opinion])
    render json: @attendance_summary_status_manager
  end

  def hr_leader_check
    summary_date = params[:summary_date].to_date.strftime("%Y-%m")
    @attendance_summary_status_managers = AttendanceSummaryStatusManager.where(summary_date: summary_date)

    raise ActiveRecord::RecordNotFound if @attendance_summary_status_managers.empty?
    return render json: {messages: '还有部门的考勤汇总未被部门HR审核'}, status: 400 if @attendance_summary_status_managers.pluck(:department_hr_checked).include?(false)
    return render json: {messages: '公司该月的考勤汇总还未被劳动关系管理员审核'}, status: 400 if @attendance_summary_status_managers.pluck(:hr_labor_relation_member_checked).include?(false)
    return render json: {messages: '公司该月的考勤汇总已经审核'}, status: 400 if @attendance_summary_status_managers.first.hr_department_leader_checked

    @attendance_summary_status_managers.each do |summary_status|
      summary_status.hr_department_leader_check(@current_employee, params[:hr_department_leader_opinion])
    end

    render json: @attendance_summary_status_managers
  end

  def hr_labor_relation_member_check
    summary_date = params[:summary_date].to_date.strftime("%Y-%m")
    @attendance_summary_status_managers = AttendanceSummaryStatusManager.where(summary_date: summary_date)

    raise ActiveRecord::RecordNotFound if @attendance_summary_status_managers.empty?
    return render json: {messages: '还有部门的考勤汇总未被部门HR审核'}, status: 400 if @attendance_summary_status_managers.pluck(:department_hr_checked).include?(false)
    return render json: {messages: '公司该月的考勤汇总已经审核'}, status: 400 if @attendance_summary_status_managers.first.hr_department_leader_checked
    return render json: {messages: '公司该月的考勤汇总已经被劳动关系管理员审核'}, status: 400 if @attendance_summary_status_managers.first.hr_labor_relation_member_checked

    @attendance_summary_status_managers.each do |summary_status|
      summary_status.hr_labor_relation_member_check(@current_employee, params[:hr_labor_relation_member_opinion])
    end

    Employee.hr_leaders.each do |employee|
      Notification.send_user_message(employee.id, 'general', "劳动关系室科员已审核完成，请您最终审核")
    end

    render json: @attendance_summary_status_managers
  end

  def administrator_check
    @attendance_summary_status_managers = AttendanceSummaryStatusManager.where(summary_date: params[:summary_date].to_date.strftime("%Y-%m"))
    raise ActiveRecord::RecordNotFound if @attendance_summary_status_managers.empty?
    return render json: {messages: '还有部门的考勤汇总未被部门HR审核'}, status: 400 if @attendance_summary_status_managers.pluck(:department_hr_checked).include?(false)
    return render json: {messages: '公司该月的考勤汇总还未被劳动关系管理员审核'}, status: 400 if @attendance_summary_status_managers.pluck(:hr_labor_relation_member_checked).include?(false)
    return render json: {messages: '公司该月的考勤汇总已经审核'}, status: 400 if @attendance_summary_status_managers.first.hr_department_leader_checked
    @attendance_summary_status_managers.each do |summary_status|
      summary_status.administrator_check
    end
    render json: @attendance_summary_status_managers
  end

  def check_list
    summary_date = params[:summary_date].to_date.strftime("%Y-%m")
    page = {page: params[:page], per_page: params[:per_page]}

    if current_employee.hr_leader? || current_employee.hr_labor_relation_member?
      department_id = params[:department_id] || current_employee.department.parent_chain.first.id
      status_name = "company_status"
    else
      department_id = FlowRelation.get_department_leader_dep_id(@current_employee).first || current_employee.department.parent_chain.first.id
      status_name = "department_status"
    end

    @current_attendance_summary_status = AttendanceSummaryStatusManager.find_by(summary_date: summary_date, department_id: department_id)
    @status = @current_attendance_summary_status.try(status_name)
    @attendance_summary_status = AttendanceSummaryStatusManager.where(summary_date: summary_date)
    @attendance_summaries = AttendanceSummary.where(attendance_summary_status_manager_id: @current_attendance_summary_status.try(:id))

    %w(employee_name employee_no).each do |key|
      @attendance_summaries = @attendance_summaries.where("#{key} like ?", "%#{params[key]}%") if params[key]
    end

    @attendance_summaries = set_page_meta(@attendance_summaries, page)
  end

  def update
    family_planning_leave_diff_days = eval("#{summary_params[:family_planning_leave]} - #{@attendance_summary.family_planning_leave}")
    recuperate_leave_diff_days = eval("#{summary_params[:recuperate_leave]} - #{@attendance_summary.recuperate_leave}")
    paid_leave = eval("#{@attendance_summary.paid_leave} + #{recuperate_leave_diff_days} + #{family_planning_leave_diff_days}")

    if @attendance_summary.update(summary_params.merge(paid_leave: paid_leave))
      render json: @attendance_summary
    else
      render json: {messages: @attendance_summary.errors.values.flatten.join(",")}, status: 400
    end
  end

  def export_xls
    summary_date = params[:summary_date].to_date.strftime("%Y-%m")
    condition = {summary_date: summary_date}

    if !current_employee.hr_leader? && !current_employee.hr_labor_relation_member? && current_employee.name != 'administrator'
      department_id = current_employee.department.parent_chain.first.id
      condition.merge!(department_id: department_id)
    end

    @summary = AttendanceSummary
      .joins(:attendance_summary_status_manager)
      .where(attendance_summary_status_managers: condition)

    attendance_summary_excel = Excel::AttendanceSummaryWriter.new(@summary).write_excel

    send_file(attendance_summary_excel.path, filename: attendance_summary_excel.filename)
  end

  def index
    result = parse_query_params!('attendance_summary')
    render json: {messages: result[:error]}, status: 400 and return unless result[:error].blank?
    relations, conditions, sorts, page = result.values

    if current_employee.hr_labor_relation_member? || current_employee.name == 'administrator'
      @attendance_summaries = AttendanceSummary.joins(relations)
    else
      @attendance_summaries = AttendanceSummary.joins(relations)
        .joins(:attendance_summary_status_manager)
        .where(attendance_summary_status_managers: {department_id: current_employee.department.parent_chain.first.id})
    end

    conditions.each do |condition|
      @attendance_summaries = @attendance_summaries.where(condition)
    end
    @attendance_summaries = set_page_meta @attendance_summaries, page
  end

  def show
    @attendance_summary = AttendanceSummary.find(params[:id])
  end

  def import
    unless params[:month]
      Notification.send_system_message(@current_employee.id, {error_messages: '月份不能为空'})
      return render text: ''
    end
    attachment = Attachment.find_by(id: params[:attachment_id])
    @importer = Excel::AttendanceSummaryImporter.new(attachment.full_path).parse_data
    if @importer.valid?
      @exporter = Excel::AttendanceSummaryExporter.new(attachment.full_path).parse_data
      if @exporter.valid?
        @importer.import(params[:month], @current_employee, params[:department_id])
        @excel = @exporter.write_csv
        render json: @excel
      else
        render json: {messages: (@importer.error + @exporter.error).join(",")}, status: 400
      end
    else
      render json: {messages: (@importer.error).join(",")}, status: 400
    end
  end

  def attendance_summary_department_list
    result = AttendanceSummaryStatusManager.where(summary_date:params[:summary_date]).inject([]) do |result, value|
      result << {department_id: value.department_id, department_name: value.department_name}
      result
    end
    render json: {messages: result}
  end

  private
  def query_params
    %I(employee_name employee_no).inject("") do |result, key|
      result += "#{key} like '%#{params[key]}%'" if params[key]
      result
    end
  end

  # def hr_leader?
  #   permission = Permission.find_by(controller: 'attendance_summaries', action: 'hr_leader_check')
  #   current_employee.has_permission?(current_employee.employee_bits, permission)
  # end

  def summary_params
    params.permit(:family_planning_leave, :recuperate_leave, :station_place, :remark, :evection)
  end

  def find_status_manager
    department_id = current_employee.department.parent_chain.first.id
    summary_date = params[:summary_date].to_date.strftime("%Y-%m")
    @attendance_summary_status_manager = AttendanceSummaryStatusManager.find_by(summary_date: summary_date, department_id: department_id)
    raise ActiveRecord::RecordNotFound if @attendance_summary_status_manager.nil?
  end

  def check_update_permission
    @attendance_summary = AttendanceSummary.find(params[:id])
    permission = Permission.find_by(controller: 'attendance_summaries', action: 'hr_leader_check')
    attendance_summary_status = @attendance_summary.attendance_summary_status_manager
    has_hr_department_leader_check_permission = current_employee.has_permission?(current_employee.employee_bits, permission)

    if has_hr_department_leader_check_permission && attendance_summary_status.hr_department_leader_checked == true
      return render json: {messages: '领导已审核不能再进行更改'}, status: 400
    end

    if attendance_summary_status.department_hr_checked == true && !has_hr_department_leader_check_permission
      return render json: {messages: '部门HR已经确认不能再进行修改'}, status: 400
    end
  end
end

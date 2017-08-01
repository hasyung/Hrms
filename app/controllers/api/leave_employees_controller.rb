class Api::LeaveEmployeesController < ApplicationController
  include ExceptionHandler
  before_filter :get_leave_employees, only: [:index, :export_to_xls]

  def index
    @leave_employees = set_page_meta @leave_employees.uniq, @page
    render template: '/api/leave_employees/index'
  end

  def show
    @leave_employee = LeaveEmployee.find(params[:id])
  end

  def update
    return render json: {messages: '离职时间选择不能大于今天的日期'}, status: 400 if params[:change_date].to_date > Date.today

    @leave_employee = LeaveEmployee.find(params[:id])
    @leave_employee.update(change_date: params[:change_date], employment_status: params[:employment_status], file_no: params[:file_no])
    render json: {messages: '更新成功'}
  end

  def export_to_xls
    excel = Excel::LeaveEmployeeWriter.new(@leave_employees).write_excel
    send_file(excel.path, filename: excel.filename)
  end

  private
  def get_leave_employees
    result = parse_query_params!('leave_employee')
    render json: {messages: result[:error]}, status: 400 and return unless result[:error].blank?
    relations, conditions, sorts, @page = result.values

    @leave_employees = LeaveEmployee.joins(relations).order(change_date: :desc)
    if !(@current_employee.hr? and !@current_employee.department_hr?) and !@current_employee.company_leader?
      department_ids = @current_employee.get_departments_for_role
      if department_ids.present?
        @leave_employees = @leave_employees.joins("JOIN departments ON departments.full_name = leave_employees.department")
        .where("departments.id in (?) or leave_employees.id = #{@current_employee.id}", department_ids)
      else
        @leave_employees = @leave_employees.where("leave_employees.id = #{@current_employee.id}")
      end
    end

    @leave_employees = @leave_employees.where(id: params[:leave_employee_ids].split(',')) if params[:leave_employee_ids]
    conditions.each do |condition|
      @leave_employees = @leave_employees.where(condition)
    end
  end
end

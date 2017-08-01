class Api::EarlyRetireEmployeesController < ApplicationController
  include ExceptionHandler
  before_filter :get_early_retire_employees, only: [:index, :export_to_xls]

  def index
    @early_retire_employees = set_page_meta @early_retire_employees.uniq, @page
    render template: '/api/early_retire_employees/index'
  end

  def show
    @early_retire_employee = EarlyRetireEmployee.find(params[:id])
  end

  def update
    return render json: {messages: '退养时间选择不能大于今天的日期'}, status: 400 if params[:change_date].to_date > Date.today

    @early_retire_employee = EarlyRetireEmployee.find(params[:id])
    @early_retire_employee.update(change_date: params[:change_date], file_no: params[:file_no])
    render json: {messages: '更新成功'}
  end

  def export_to_xls
    excel = Excel::EarlyRetireEmployeeWriter.new(@early_retire_employees).write_excel
    send_file(excel.path, filename: excel.filename)
  end

  private
  def get_early_retire_employees
    result = parse_query_params!('early_retire_employee')
    render json: {messages: result[:error]}, status: 400 and return unless result[:error].blank?
    relations, conditions, sorts, @page = result.values
    sorts = "change_date desc"

    @early_retire_employees = EarlyRetireEmployee.joins(relations).joins(
      "JOIN departments ON departments.full_name = early_retire_employees.department"
    ).order(
      "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no"
    )

    if !(@current_employee.hr? and !@current_employee.department_hr?) and !@current_employee.company_leader?
      department_ids = @current_employee.get_departments_for_role

      if department_ids.present?
        @early_retire_employees = @early_retire_employees.joins("JOIN departments ON departments.full_name = early_retire_employees.department")
        .where("departments.id in (?) or early_retire_employees.id = #{@current_employee.id}", department_ids)
      else
        @early_retire_employees = @early_retire_employees.where("early_retire_employees.id = #{@current_employee.id}")
      end
    end

    @early_retire_employees = @early_retire_employees.where(id: params[:early_retire_employee_ids].split(',')) if params[:early_retire_employee_ids]
    conditions.each do |condition|
      @early_retire_employees = @early_retire_employees.where(condition)
    end
  end
end

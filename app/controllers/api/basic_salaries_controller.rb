class Api::BasicSalariesController < ApplicationController
  include ExceptionHandler

  def compute
    if params[:month]
      message = SalaryPersonSetup.check_compute(params[:month])
      return render json: {basic_salaries: [], messages: message} if message

      is_success, messages = BasicSalary.compute(params[:month])
      return render json: {basic_salaries: [], messages: messages || "计算发生错误"}, status: 400 if !is_success

      @basic_salaries = BasicSalary.joins(employee: :department).order(
        "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no"
        ).where("basic_salaries.month = '#{params[:month]}'")
      page = parse_query_params!("basic_salary").values.last
      @basic_salaries = set_page_meta(@basic_salaries, page)
      render template: 'api/basic_salaries/index'
    else
      Notification.send_system_message(current_employee.id, {error_messages: '月份不能为空'})
      return render text: ''
    end
  end

  def index
    result = parse_query_params!('basic_salary')
    render json: {messages: result[:error]}, status: 400 and return unless result[:error].blank?
    relations, conditions, sorts, page = result.values

    @basic_salaries = BasicSalary.joins(employee: :department).joins(relations).order(
      "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no"
    ).order(sorts)

    conditions.each do |condition|
      @basic_salaries = @basic_salaries.where(condition)
    end
    @basic_salaries = set_page_meta @basic_salaries, page
  end

  def export_approval
    if(params[:month])
      basic_salaries = BasicSalary.joins(employee: :department)
        .includes(employee: [:basic_salaries, :keep_salaries]).order(
        "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no"
        ).where("basic_salaries.month = '#{params[:month]}'")
      if basic_salaries.blank?
        Notification.send_system_message(current_employee.id, {error_messages: '导出数据为空'})
        return render text: ''
      end
      excel = Excel::BasicSalaryExportor.export_approval(basic_salaries, params[:month])
      send_file(excel[:path], filename: excel[:filename])
    else
      Notification.send_system_message(current_employee.id, {error_messages: '条件不足'})
      render text: ''
    end
  end

  def export_nc
    if(params[:month])
      basic_salaries = BasicSalary.joins(employee: :department)
        .includes(employee: [:basic_salaries, :keep_salaries]).order(
        "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no"
        ).where("basic_salaries.month = '#{params[:month]}'")
      if basic_salaries.blank?
        Notification.send_system_message(current_employee.id, {error_messages: '导出数据为空'})
        return render text: ''
      end
      excel = Excel::BasicSalaryExportor.export_nc(basic_salaries, params[:month])
      send_file(excel[:path], filename: excel[:filename])
    else
      Notification.send_system_message(current_employee.id, {error_messages: '条件不足'})
      render text: ''
    end
  end

  def update
    @basic_salary = BasicSalary.find(params[:id])

    if @basic_salary.update(basic_salary_params)
      render template: '/api/basic_salaries/show'
    else
      render json: {messages: '修改失败'}, status: 400
    end
  end

  private
  def basic_salary_params
    params.permit(:add_garnishee, :remark)
  end
end
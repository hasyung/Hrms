class Api::KeepSalariesController < ApplicationController
  include ExceptionHandler

  def index
    result = parse_query_params!('keep_salary')
    render json: {messages: result[:error]}, status: 400 and return unless result[:error].blank?
    relations, conditions, sorts, page = result.values

    @keep_salaries = KeepSalary.joins(employee: :department).joins(relations).order(sorts).order(
      "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no"
    )
    
    conditions.each do |condition|
      @keep_salaries = @keep_salaries.where(condition)
    end

    @keep_salaries = set_page_meta @keep_salaries, page
  end

  def compute
    if params[:month]
      message = SalaryPersonSetup.check_compute(params[:month])
      return render json: {keep_salaries: [], messages: message} if message

      is_success, messages = KeepSalary.compute(params[:month])
      return render json: {keep_salaries: [], messages: messages || "计算发生错误"}, status: 400 if !is_success

      @keep_salaries = KeepSalary.joins(employee: :department).order(
        "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no"
      ).where("keep_salaries.month = '#{params[:month]}'")

      page = parse_query_params!("keep_salary").values.last
      @keep_salaries = set_page_meta(@keep_salaries, page)

      render template: 'api/keep_salaries/index'
    else
      render json: {messages: "计算月份是必须的参数"}, status: 400
    end
  end

  def export_nc
    #
  end

  def export_approval
    #
  end

  def update
    @keep_salary = KeepSalary.find(params[:id])

    if @keep_salary.update(keep_salary_params)
      render template: '/api/keep_salaries/show'
    else
      render json: {messages: '修改失败', reason: @keep_salary.errors.full_messages}, status: 400
    end
  end

  private

  def keep_salary_params
    params.permit(:add_garnishee, :remark)
  end
end

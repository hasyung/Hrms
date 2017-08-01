class Api::SalaryOverviewsController < ApplicationController
  before_action :check_month, only: [:compute]

  def index
    result = parse_query_params!('salary_overview')
    render json: {messages: result[:error]}, status: 400 and return unless result[:error].blank?
    relations, conditions, sorts, page = result.values

    @salary_overviews = SalaryOverview.joins(employee: :department).joins(relations).order(
      "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no"
    ).order(sorts)

    conditions.each do |condition|
      @salary_overviews = @salary_overviews.where(condition)
    end

    @salary_overviews = set_page_meta @salary_overviews, page
  end

  def compute
    month = params[:month]

    if month
      message = SalaryPersonSetup.check_compute(params[:month])
      return render json: {salary_overviews: [], messages: message} if message

      begin
        is_success, messages = SalaryOverview.compute(params[:month])
        return render json: {salary_overviews: [], messages: messages || "计算发生错误"}, status: 400 if !is_success

        @salary_overviews = SalaryOverview.joins(employee: :department).order(
          "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no"
        ).where("salary_overviews.month = '#{params[:month]}'")

        page = parse_query_params!("salary_overview").values.last
        @salary_overviews = set_page_meta(@salary_overviews, page)

        render template: 'api/salary_overviews/index'
      end
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
    @salary_overview = SalaryOverview.find(params[:id])

    if @salary_overview.update(salary_overview_params)
      render template: '/api/salary_overviews/show'
    else
      render json: {messages: '修改失败'}, status: 400
    end
  end

  private
  def salary_overview_params
    params.permit(:remark)
  end

  def check_month
    if params[:month].blank?
      Notification.send_system_message(current_employee.id, {error_messages: '月份不能为空'})
      return render text: ''
    end
  end
end

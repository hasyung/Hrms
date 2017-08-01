class Api::AirlineFeesController < ApplicationController
  before_action :check_month, only: [:compute_oversea_food_fee]

  def compute_oversea_food_fee
    is_success, messages = AirlineFee.compute_oversea_food_fee(params[:month])
    return render json: {airline_fees: [], messages: messages || "计算发生错误"}, status: 400 if !is_success

    #计算完境外餐食补贴之后，拆分员工空勤灶
    AirlineFee.split_airline_fee(params[:month])

    @airline_fees = AirlineFee.joins(employee: :department).order(
      "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no"
    ).where(month: params[:month])

    render template: 'api/airline_fees/index'
  end

  def export
    send_file()
  end

  def update
    @airline_fee = AirlineFee.find params[:id]

    if @airline_fee.update(update_params)
      render template: 'api/airline_fees/show'
    else
      return render json: {messages: '修改失败'}, status: 400
    end
  end

  def index
    result = parse_query_params!('airline_fee')
    render json: {messages: result[:error]}, status: 400 and return unless result[:error].blank?
    relations, conditions, sorts, page = result.values

    @airline_fees = AirlineFee.joins(employee: :department).joins(
      relations
    ).order(
      "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no"
    ).order(sorts)

    conditions.each do |condition|
      @airline_fees = @airline_fees.where(condition)
    end

    @airline_fees = set_page_meta @airline_fees, page
  end

  private
  def update_params
    params.permit(:add_garnishee, :remark)
  end

  def check_month
    if params[:month].blank?
      Notification.send_system_message(current_employee.id, {error_messages: '月份或人员类别不能为空'})
      return render text: ''
    end
  end
end

class Api::OfficialCarsController < ApplicationController

  def index
    result = parse_query_params!('official_car')
    render json: {messages: result[:error]}, status: 400 and return unless result[:error].blank?
    relations, conditions, sorts, page = result.values

    @official_cars = OfficialCar.joins(employee: [:department, :channel]).joins(relations).order(
      "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no"
    ).order(sorts)

    conditions.each do |condition|
      @official_cars = @official_cars.where(condition)
    end

    @official_cars = set_page_meta @official_cars, page
  end

  def compute
    unless params[:month]
      Notification.send_system_message(current_employee.id, {error_messages: '月份不能为空'})
      return render text: ''
    end
    
    is_success, messages = OfficialCar.compute(params[:month])
    return render json: {official_cars: [], messages: messages || "计算发生错误"}, status: 400 if !is_success

    @official_cars = OfficialCar.joins(employee: [:department, :channel]).order(
      "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no"
      ).where("official_cars.month = '#{params[:month]}'")
    page = parse_query_params!("official_car").values.last
    @official_cars = set_page_meta(@official_cars, page)

    render template: 'api/official_cars/index'
  end

  def update
    @official_car = OfficialCar.find(params[:id])

    if @official_car.update(official_car_params)
      render template: '/api/official_cars/show'
    else
      render json: {messages: '修改失败'}, status: 400
    end
  end

  private
  def official_car_params
    params.permit(:add_garnishee, :remark)
  end
end

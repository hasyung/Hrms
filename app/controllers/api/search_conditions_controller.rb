class Api::SearchConditionsController < ApplicationController
  include ExceptionHandler

  skip_before_action :check_action_register, only: [:index]
  skip_before_action :check_permission, only: [:index]

  def index
    @conditions = @current_employee.search_conditions.where(code: params[:code])
  end

  def create
    @condition = @current_employee.search_conditions.where(code: params[:code], name: params[:name]).first
    if @condition.blank?
      @condition = @current_employee.search_conditions.new search_condition_params
    else
      @condition.condition = params[:condition]
    end
    unless @condition.save
      render json: {messages: condition.errors.values.flatten.join(",")}, status: 400 and return
    end
  end

  def destroy
    condition = Employee::SearchCondition.find_by(id: params[:id])
    if condition.present? && condition.destroy
      render json: {messages: "查询条件删除成功"}
    else
      render json: {messages: '查询条件删除失败'}, status: 400
    end
  end

  private
  def search_condition_params
    params.permit(:name, :code, :condition)
  end

end

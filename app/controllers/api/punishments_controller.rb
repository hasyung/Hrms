class Api::PunishmentsController < ApplicationController
  include ExceptionHandler

  def index
    employee = Employee.find(params[:id])
    @punishments = employee.punishments
    @punishments = @punishments.where(genre: params[:genre]) if params[:genre]
    key = params[:genre] == '奖励' ? 'rewards' : 'punishments'
    render json: {key => @punishments}
  end

  def create
    employee = Employee.find(params[:id])
    @punishment = employee.punishments.new(punishment_params)
    if(@punishment.save)
      key = params[:genre] == '奖励' ? 'reward' : 'punishment'
      render json: {key => @punishment}
    else
      render json: {messages: @punishment.errors.values.flatten.join(",")}, status: 400
    end
  end

  private
  def punishment_params
    params.permit(:category, :desc, :start_date, :end_date, :genre, :reward_date)
  end

end
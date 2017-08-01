class Api::FavNotesController < ApplicationController
  skip_before_action :check_action_register
  skip_before_action :check_permission
  skip_after_action :record_log

  def index
    @notes = @current_employee.fav_notes
  end

  def create
    @item = @current_employee.fav_notes.create(create_params)
    render json: {messages: '成功'}
  end

  def destroy
    item = @current_employee.fav_notes.where(id: params[:id]).first
    if item.destroy
      render json: {messages: '成功'}
    else
      render json: {messages: '错误'}, status: 400
    end
  end

  private
  def create_params
    params.permit(:note)
  end
end

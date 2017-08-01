class Api::SortController < ApplicationController
  include ExceptionHandler

  def index
    case sort_params[:category]
    when 'department'
      Department.sort(sort_params[:current_id], sort_params[:target_id])
    when 'position'
      Position.sort(sort_params[:current_id], sort_params[:target_id])
    when 'employee'
      Employee.sort(sort_params[:current_id], sort_params[:target_id])
    else
      render json: {messages: 'failed'}, status: 400 and return
    end
    render json: {messages: 'success'} and return
  end

  private
  def sort_params
    params.permit(:category, :current_id, :target_id, :format)
  end

end

class Api::CalcStepsController < ApplicationController
  def search
    @employee_id = params[:employee_id]
    @month = params[:month]
    @category = params[:category]

    condition = {employee_id: @employee_id, month: @month, category: @category}
    @calc_step = CalcStep.where(condition).first

    if !@calc_step
      render json: {messages: '没有找到计算过程'} and return
    end
  end
end
class Api::EnumController < ApplicationController
  include ExceptionHandler

  skip_before_action :check_action_register
  skip_before_action :check_permission

  def index
    begin
      @result = DataMappingService.new(params[:key]).map
      render json: {result: @result}
    rescue => ex
      render :json => {message: "参数传递规则不正确"}, status: 400
    end
  end
end

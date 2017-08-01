class Api::SessionsController < ApplicationController
  include ExceptionHandler

  skip_before_action :authenticate_user!, only: [:create]

  def create
    employee = Employee.authenticate(signin_params[:employee_no], signin_params[:password])

    if employee
      token = employee.authenticate_tokens.generate_token.token
      cookies[:token] = token
      render json: {messages: "login success"}, status: 200 and return
    end

    render json: {messages: "登陆密码/工号错误"}, status: 400
  end

  def destroy
    @token = AuthenticateToken.find_by(token: access_token)
    @token.destroy
    cookies[:token] = nil

    render json: {messages: "登出成功"}
  end

  private

  def signin_params
    params.require(:user).permit(:employee_no, :password)
  end
end

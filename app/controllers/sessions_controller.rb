require 'socket'

class SessionsController < ApplicationController
  layout false
  skip_before_action :authenticate_user!, only: [:new, :create, :singpoint]
  skip_before_action :check_action_register
  skip_before_action :check_permission

  def new
  end

  def singpoint
    @employee = Employee.unscoped.where(is_delete: false, employee_no: params[:sysuserid]).first

    if @employee
      auth_status, auth_result = Api::SingleSignOn.valid_trust_code(params[:sysuserid])
      if auth_status && params[:mykey].present? && auth_result == params[:mykey]
        @access_token = @employee.authenticate_tokens.generate_token
        @employee.update(last_login_ip: request.remote_ip)
        cookies[:token] = @access_token.token
        cookies[:single_point] = true
        redirect_to "/" and return
      else
        flash[:error] = auth_result
      end
    else
      flash[:error] = "员工编号错误!"
    end
    redirect_to "/sessions/new"
  end

  def create
    if (FileTest::exist?('/var/new_session.text'))
      @employee = Employee.unscoped.where(is_delete: false, employee_no: signin_params[:employee_no]).first

      if @employee
        if @employee.is_system
          @employee = Employee.authenticate(signin_params[:employee_no], signin_params[:password])
        else
          flash[:error] = valid_employee_from_single
          cookies[:single_point] = true
        end
      end
    else
      @employee = Employee.authenticate(signin_params[:employee_no], signin_params[:password])
    end

    if @employee && flash[:error].blank?
      @access_token = @employee.authenticate_tokens.generate_token
      @employee.update(last_login_ip: request.remote_ip)
      cookies[:token] = @access_token.token

      if @employee.is_admin
        redirect_to "/admin/" and return
      else
        redirect_to "/" and return
      end
    end

    flash[:error] = "员工编号或密码错误!" if flash[:error].blank?
    redirect_to "/sessions/new"
  end

  def destroy
    @token = AuthenticateToken.find_by(token: access_token)
    @token.destroy
    cookies[:token] = nil

    redirect_to "/sessions/new"
  end

  private

  def signin_params
    params.require(:user).permit(:employee_no, :password)
  end

  def valid_employee_from_single
    Api::SingleSignOn.valid_effect_user(signin_params[:employee_no], signin_params[:password])
  end
end

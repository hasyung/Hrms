class AdminController < ApplicationController
  layout "admin"

  helper_method :current_admin

  skip_before_action :authenticate_user!
  skip_before_action :load_controller_action
  skip_before_action :check_action_register
  skip_before_action :check_permission

  skip_after_action :record_log

  before_action :require_system_admin

  def require_system_admin
    unless current_employee
      redirect_to "/sign_in" and return
    end

    unless current_employee.is_admin
      redirect_to "/"
    end
  end

  def current_admin
    current_employee.try(:is_admin) ? current_employee : nil
  end
end

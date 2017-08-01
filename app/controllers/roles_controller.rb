class RolesController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :check_action_register
  skip_before_action :check_permission

  layout "roles"

  def index
    @roles = current_employee.get_my_roles
    @main_role = @roles.first
  end
end

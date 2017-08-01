class Api::PermissionsController < ApplicationController
  include ExceptionHandler

  def index
    render json: {permissions: Permission.all}
  end
end

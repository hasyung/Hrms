class ExternalController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :load_controller_action
  skip_before_action :check_action_register
  skip_before_action :check_permission

  skip_after_action :record_log
end
class Api::Me::NotificationsController < ApplicationController
  include ExceptionHandler

  before_filter :get_unread_notifications
  skip_before_action :check_action_register
  skip_before_action :check_permission

  def index
    per_page = params[:per_page].blank? ? 20 : params[:per_page].to_i
    @unread_count = @notifications.size
    if params[:anchor_id].blank?
      @notifications = @current_employee.notifications.limit(per_page)
    else
      @notifications = @current_employee.notifications.where("id < ?", params[:anchor_id].to_i).limit(per_page)
    end
    render template: '/api/me/notifications/index'
  end

  def update
    if params[:anchor_id].present?
      @notifications = @notifications.where("id <= ?", params[:anchor_id].to_i)
    end
    @notifications.update_all(confirmed_at: DateTime.now, confirmed: true)
    @unread_count = 0
    render template: '/api/me/notifications/index'
  end

  private
  def get_unread_notifications
    @notifications = @current_employee.notifications.unread
  end

end

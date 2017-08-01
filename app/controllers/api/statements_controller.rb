class Api::StatementsController < ApplicationController
  skip_before_action :check_action_register, only: [:position_change_record_channel]
  skip_before_action :check_permission, only: [:position_change_record_channel]

  def new_leave_employee_summary
    hash = {}
    date          = Date.parse(params[:month] + '-01')
    start_date    = date.beginning_of_month
    end_date      = date.end_of_month
    new_employees = Employee.includes(:department).where(
      "(join_scal_date >= ? AND join_scal_date <= ? and start_internship_date IS NULL) OR (start_internship_date >= ? AND start_internship_date <= ?)", start_date, end_date, start_date, end_date
    ).group_by{|item| item.department.full_name.split("-").first}
    new_employees.each do |key, values|
      hash[key] = {}
      hash[key]["new"] = values.size
    end
    leave_employees = LeaveEmployee.where(
      "change_date >= ? and change_date <= ?", start_date, end_date
    ).group_by{|item| item.department.split("-").first}
    leave_employees.each do |key, values|
      hash[key] ||= {}
      hash[key]["leave"] = values.size
    end
    render json: { "new_leave_employee_summary" => hash }
  end

  def position_change_record_pie
    month = params[:month]
    channel_name = params[:channel_name]
    position_change_record_pie = PositionRecord.where("DATE_FORMAT(change_date,'%Y-%m')=? and channel_name=?",month,channel_name).group(:pre_channel_name).count('employee_id')
    render json: { "position_change_record_pie" => position_change_record_pie}
  end

  def position_change_record_channel
    month = params[:month]
    position_change_record_channel = PositionRecord
      .where("DATE_FORMAT(change_date,'%Y-%m')=?", month)
      .pluck(:channel_name).uniq

    render json: {channels: position_change_record_channel}
  end
end

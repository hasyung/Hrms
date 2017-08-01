class Api::VacationsController < ApplicationController
  include ExceptionHandler

  skip_before_action :check_action_register, :check_permission
  skip_after_action :record_log

  def summary
    render json: {vacation_summary: current_employee.vacation_summary}
  end

  def calc_days
    params[:start_time] = "#{params[:start_time]}T#{Setting.daily_working_hours.morning}.000Z" if params[:start_time].size <= 10
    params[:end_time] = "#{params[:end_time]}T#{Setting.daily_working_hours.afternoon_end}.000Z" if params[:end_time].size <= 10

    start_time = Time.parse(params[:start_time])
    end_time = Time.parse(params[:end_time])

    #获取班制
    work_shifts = current_employee.work_shifts.where(end_time:nil).first.try(:work_shifts)

    condition = {
      vacation_type: params[:vacation_type],
      start_date: start_time.beginning_of_day.to_date,
      end_date: end_time.beginning_of_day.to_date,
      start_time: start_time,
      end_time: end_time,
      employee_id: params[:receptor_id] || current_employee.id,
      work_shifts: work_shifts || "行政班"
    }

    render json: VacationRecord.cals_days(condition)
  end

  def import_annual_days
    attachment = Attachment.find_by(id: params[:attachment_id])

    begin
      Excel::VacationRecordImportor.import(attachment.full_path)
    rescue Exception => e
      render json: {messages: e.to_s}, status: 400
      return 

    end
    render json: {messages: "导入成功"}
  end
end

class Api::Me::WorkExperiencesController < ApplicationController
  include ExceptionHandler

  skip_before_action :check_action_register
  skip_before_action :check_permission
  
  def index
    work_experiences = @current_employee.work_experiences
    render json:{ work_experiences: work_experiences }
  end

  def create
    work_experience = @current_employee.work_experiences.new work_experience_params
    if work_experience.save
      ChangeRecordWeb.save_record('employee_update', @current_employee).send_notification
      render json:{ work_experience: work_experience }
    else
      render json: {messages: work_experience.errors.values.flatten.join(",")}, status: 400
    end
  end

  def update
    work_experience = @current_employee.work_experiences.find(params[:id])
    if work_experience.update(work_experience_params)
      ChangeRecordWeb.save_record('employee_update', @current_employee).send_notification
      render json:{ work_experience: work_experience }
    else
      render json: {messages: work_experience.errors.values.flatten.join(",")}, status: 400
    end
  end

  def destroy
    work_experience = @current_employee.work_experiences.find(params[:id])
    if work_experience.destroy
      ChangeRecordWeb.save_record('employee_update', @current_employee).send_notification
      render json: {messages: "工作经历删除成功"}
    else
      render json: {messages: "工作经历删除失败"}, status: 400
    end
  end

  private
  def work_experience_params
    safe_params [:company, :department, :position, :job_desc, :job_title, 
      :start_date, :end_date, :witness]
  end
end

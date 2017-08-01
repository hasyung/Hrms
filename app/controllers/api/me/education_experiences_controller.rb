class Api::Me::EducationExperiencesController < ApplicationController
  include ExceptionHandler

  skip_before_action :check_action_register
  skip_before_action :check_permission
  
  def index
    @education_experiences = @current_employee.education_experiences
  end

  def create
    @education_experience = @current_employee.education_experiences.new education_experience_params
    if @education_experience.save
      ChangeRecordWeb.save_record('employee_update', @current_employee).send_notification
      render template: '/api/me/education_experiences/show'
    else
      render json: {messages: @education_experience.errors.values.flatten.join(",")}, status: 400
    end
  end

  def update
    @education_experience = @current_employee.education_experiences.find(params[:id])
    if @education_experience.update(education_experience_params) 
      ChangeRecordWeb.save_record('employee_update', @current_employee).send_notification
      render template: '/api/me/education_experiences/show'
    else
      render json: {messages: @education_experience.errors.values.flatten.join(",")}, status: 400
    end
  end

  def destroy
    education_experience = @current_employee.education_experiences.find(params[:id])
    if education_experience.destroy
      ChangeRecordWeb.save_record('employee_update', @current_employee).send_notification
      render json: {messages: "教育经历删除成功"}
    else
      render json: {messages: "教育经历删除失败"}, status: 400
    end
  end

  private
  def education_experience_params
    safe_params [:school, :major, :admission_date, :graduation_date, :education_background_id, 
      :education_nature_id, :degree_id, :witness]
  end
end

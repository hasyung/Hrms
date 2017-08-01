class Api::Me::FamilymembersController < ApplicationController
  include ExceptionHandler

  skip_before_action :check_action_register
  skip_before_action :check_permission

  def index
    if params[:relation].present?
      @family_members = @current_employee.family_members.where(relation: params[:relation])
    else
      @family_members = @current_employee.family_members
    end
    render json:{ family_members: @family_members }
  end

  def create
    family_member = @current_employee.family_members.new family_member_params
    if family_member.save
      ChangeRecordWeb.save_record('employee_update', @current_employee).send_notification
      render json:{ family_member: family_member }
    else
      render json: {messages: family_member.errors.values.flatten.join(",")}, status: 400
    end
  end

  def update
    family_member = @current_employee.family_members.find(params[:id])
    if family_member.update(family_member_params)
      ChangeRecordWeb.save_record('employee_update', @current_employee).send_notification
      render json:{ family_member: family_member }
    else
      render json: {messages: family_member.errors.values.flatten.join(",")}, status: 400
    end
  end

  def destroy
    family_member = @current_employee.family_members.find(params[:id])
    if family_member.destroy
      ChangeRecordWeb.save_record('employee_update', @current_employee).send_notification
      render json: {messages: "家庭成员删除成功"}
    else
      render json: {messages: "家庭成员删除失败"}, status: 400
    end
  end

  private
  def family_member_params
    safe_params [:name, :native_place, :birthday, :start_work_date, :married_date, :gender, :relation,
      :nation, :position,  :company, :mobile, :residence_booklet, :political_status, :education_background,
      :relation_type, :identity_no]
  end
end

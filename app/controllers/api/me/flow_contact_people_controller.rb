class Api::Me::FlowContactPeopleController < ApplicationController
  include ExceptionHandler

  skip_before_action :check_action_register
  skip_before_action :check_permission

  def index
    @employees = Employee.joins(:department)
      .where(id: current_employee.flow_contact_people) 
      .includes(:department)   
  end 

  def create
    @employee = Employee.find(params[:employee_id])
    employee_ids = (current_employee.flow_contact_people << params[:employee_id]).uniq

    current_employee.update(flow_contact_people: employee_ids)
    render template: '/api/me/flow_contact_people/show'
  end

  def destroy
    employee_id = params[:id].to_i
    if current_employee.flow_contact_people.include?(employee_id)
      employee_ids = current_employee.flow_contact_people - [employee_id]
      
      current_employee.update(flow_contact_people: employee_ids)
      render json: {messages: '联系人删除成功'}
    else
      raise ActiveRecord::RecordNotFound
    end
  end
end

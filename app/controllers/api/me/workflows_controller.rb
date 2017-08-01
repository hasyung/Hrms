class Api::Me::WorkflowsController < ApplicationController
  include ExceptionHandler

  skip_before_action :check_action_register
  skip_before_action :check_permission
  before_action :check_flow_type

  def index
    @workflows = Flow.where(receptor_id: current_employee.id, type: params[:flow_type])
    @receptor = current_employee
    templ_name = params[:flow_type].sub("Flow::", "").underscore

    render template: "/api/me/workflows/#{templ_name}"
  end

  def show
    @workflow = Flow.find(params[:id])
    render template: "/api/workflows/show"
  end

  def check_flow_type
    access_workflow = %w(Flow::Resignation Flow::RenewContract Flow::AdjustPosition Flow::EarlyRetirement)

    render json: {messages: '流程参数错误'}, status: 400 and return unless access_workflow.include?(params[:flow_type])
  end
end

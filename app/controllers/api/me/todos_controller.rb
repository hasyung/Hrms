class Api::Me::TodosController < ApplicationController
  include ExceptionHandler

  skip_before_action :check_action_register
  skip_before_action :check_permission

  def index
    @workflows = Flow.joins(:receptor).where("reviewer_ids like ?", "%- #{current_employee.id}\n%")
  end  

  def show
    @workflow = Flow.find(params[:id])

    render template: '/api/workflows/show'
  end
end

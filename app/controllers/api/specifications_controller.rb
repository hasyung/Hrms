class Api::SpecificationsController < ApplicationController
  include ExceptionHandler

  def create
    @position = Position.find(params[:position_id])
    @specification = @position.build_specification(specification_params)

    if @specification.save
      render template: '/api/specifications/show'
    else
      render json: {messages: @specification.errors.values.flatten.join(",")}, status: 400
    end
  end

  def update
    @position = Position.find(params[:position_id])
    @specification = @position.specification

    if @specification.update(specification_params)
      ChangeRecordWeb.save_record("position_update", @position).send_notification
      render template: '/api/specifications/show'
    else
      render json: {messages: @specification.errors.values.flatten.join(",")}, status: 400
    end
  end

  def show
    @specification = Position.find(params[:position_id]).specification
  end

  private
  def specification_params
    params.permit(:duty, :personnel_permission,
                                          :financial_permission, :business_permission,
                                          :superior, :underling, :internal_relation,
                                          :external_relation, :qualification)
  end
end

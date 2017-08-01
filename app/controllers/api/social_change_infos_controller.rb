class Api::SocialChangeInfosController < ApplicationController
  include ExceptionHandler

  def index
    result = parse_query_params!('social_change_info')
    render json: {messages: result[:error]}, status: 400 and return unless result[:error].blank?
    relations, conditions, sorts, page = result.values

    @social_change_infos = SocialChangeInfo.includes(employee: [:social_person_setup, :labor_relation])
      .joins(relations).order(sorts)

    conditions.each do |condition|
      @social_change_infos = @social_change_infos.where(condition)
    end
    @social_change_infos = set_page_meta @social_change_infos, page
  end

  def show
    @social_change_info = SocialChangeInfo.find(params[:id])
  end

  def update
    @social_change_info = SocialChangeInfo.find(params[:id])
    return render json: {messages: '该员工已离职'}, status: 400 unless @social_change_info.employee
    
    if(@social_change_info.category == '停薪调' || @social_change_info.category == '停薪调停止')
      person_setup = SocialPersonSetup.unscoped{ @social_change_info.employee.social_person_setup }
      person_setup.update(is_delete: (@social_change_info.category == '停薪调')) if person_setup
    end

    @social_change_info.update(params.permit(:state))
    render json: {messages: '处理成功'}
  end
end

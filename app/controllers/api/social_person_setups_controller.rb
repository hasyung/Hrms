class Api::SocialPersonSetupsController < ApplicationController
  include ExceptionHandler

  def index
    result = parse_query_params!('social_person_setup')
    render json: {messages: result[:error]}, status: 400 and return unless result[:error].blank?
    relations, conditions, sorts, page = result.values

    @social_person_setups = SocialPersonSetup.joins(employee: :department).joins(relations).order(
      "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no"
    ).order(sorts)

    conditions.each do |condition|
      @social_person_setups = @social_person_setups.where(condition)
    end
    @social_person_setups = set_page_meta @social_person_setups, page
  end

  def update
    @social_person_setup = SocialPersonSetup.find(params[:id])
    replenish_cardinalities
    if @social_person_setup.update(personage_params)
      render template: '/api/social_person_setups/show'
    else
      render json: {messages: '修改失败'}, status: 400
    end
  end

  def create
    return render json: {messages: '社保属地不能为空'}, status: 400 unless personage_params[:social_location]
    employee = Employee.find(params[:employee_id])
    return render json: {messages: '社保个人设置已存在'}, status: 400 if employee.social_person_setup

    @social_person_setup = SocialPersonSetup.unscoped.find_by(employee_id: employee.id)
    result = false

    SocialPersonSetup.transaction do
      @social_person_setup.destroy if @social_person_setup
      @social_person_setup = employee.build_social_person_setup(personage_params)
      replenish_cardinalities
      result = @social_person_setup.save
    end

    if result
      render template: '/api/social_person_setups/show'
    else
      render json: {messages: '新增失败'}, status: 400
    end
  end

  def destroy
    @social_person_setup = SocialPersonSetup.find(params[:id])
    if @social_person_setup.update(is_delete: true)
      render json: {messages: '删除成功'}
    else
      render json: {messages: '删除失败'}, status: 400
    end
  end

  def show
    @social_person_setup = SocialPersonSetup.find(params[:id])
  end

  private
  def personage_params
    params.permit(:social_location, :pension, :treatment, :unemploy, :injury, :illness, :fertility, 
      :social_account)
  end

  def replenish_cardinalities
    @social_person_setup.pension_cardinality = params[:pension_cardinality].try(:round, 2)
    @social_person_setup.treatment_cardinality = params[:other_cardinality].try(:round, 2)
    @social_person_setup.temp_cardinality = params[:temp_cardinality].try(:round, 2)
  end
end

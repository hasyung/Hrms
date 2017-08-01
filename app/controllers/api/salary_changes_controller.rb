class Api::SalaryChangesController < ApplicationController
  include ExceptionHandler

  def index
    result = parse_query_params!('salary_change')
    render json: {messages: result[:error]}, status: 400 and return unless result[:error].blank?
    relations, conditions, sorts, page = result.values

    @salary_changes = SalaryChange.includes(:salary_setup_cache, employee: [:salary_person_setup, :labor_relation])
      .joins(relations).order(sorts)

    conditions.each do |condition|
      @salary_changes = @salary_changes.where(condition)
    end
    @salary_changes = set_page_meta @salary_changes, page
  end

  def show
    @salary_change = SalaryChange.find(params[:id])
  end

  def update
    @salary_change = SalaryChange.find(params[:id])
    return render json: {messages: '该员工已离职'}, status: 400 unless @salary_change.employee

    if(@salary_change.category == '停薪调' || @salary_change.category == '停薪调停止')
      person_setup = SalaryPersonSetup.unscoped{ @salary_change.employee.salary_person_setup }
      person_setup.update(is_stop: (@salary_change.category == '停薪调')) if person_setup
    end

    if params[:state] == '已处理' && params[:salary_setup_cache]
      cache = @salary_change.salary_setup_cache
      unless cache
        cache = SalarySetupCache.create(employee_id: @salary_change.employee.id)
        cache.assign_attributes(
          position_change_date: @salary_change.position_change_record.try(:position_change_date),
          probation_end_date: @salary_change.position_change_record.try(:probation_end_date),
          channel_id: @salary_change.employee.channel_id,
          prev_channel_id: @salary_change.position_change_record.try(:prev_channel_id),
          prev_category_id: @salary_change.position_change_record.try(:prev_category_id),
          prev_department_name: @salary_change.position_change_record.try(:prev_department_name),
          prev_position_name: @salary_change.position_change_record.try(:prev_position_name),
          prev_location: @salary_change.position_change_record.try(:prev_location),
          salary_change_id: @salary_change.id
        )
      end
      cache.update(data: params[:salary_setup_cache], is_confirmed: true)
    end
    if params[:state] == '已拒绝'
      @salary_change.salary_setup_cache.try(:destroy)
    end

    @salary_change.update(params.permit(:state))
    render json: {messages: '处理成功'}
  end
end

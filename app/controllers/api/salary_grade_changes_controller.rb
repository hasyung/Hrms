class Api::SalaryGradeChangesController < ApplicationController
  def index
    result = parse_query_params!('salary_grade_change')
    render json: {messages: result[:error]}, status: 400 and return unless result[:error].blank?
    relations, conditions, sorts, page = result.values

    @salary_grade_changes = SalaryGradeChange.joins(employee: [:department]).joins(relations).order(sorts).order(
      "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no"
    )

    conditions.each do |condition|
      @salary_grade_changes = @salary_grade_changes.where(condition)
    end

    @salary_grade_changes = set_page_meta @salary_grade_changes, page 
  end

  def show
    @salary_grade_change = SalaryGradeChange.joins(employee: [:department]).find params[:id]
  end

  def update
    @salary_grade_change = SalaryGradeChange.where(id: params[:id]).first
    if @salary_grade_change.present?
      @salary_grade_change.update(form_data: params[:form_data])
      @salary_grade_change.trigger_event(params[:result])
      render json: {salary_grade_change: @salary_grade_change}
    else
      render json: {messages: '参数错误'}, status: 400
    end
  end
end

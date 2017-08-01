class Api::AgreementsController < ApplicationController

  def show
    @agreement = Agreement.find params[:id]
  end

  def index
    result = parse_query_params!('agreement')
    render json: {messages: result[:error]}, status: 400 and return unless result[:error].blank?

    relations, conditions, sorts, page = result.values
    @agreements = Agreement.joins(relations).order(start_date: :desc)

    conditions.each do |condition|
      @agreements = @agreements.where(condition)
    end

    @agreements = set_page_meta @agreements, page
  end

  def create
    @employee = Employee.find params[:employee_id]

    @agreement = @employee.agreements.create(
      employee_name:   @employee.name,
      employee_no:     @employee.employee_no,
      department_name: @employee.department.full_name,
      position_name:   EmployeePosition.full_position_name(@employee.employee_positions),
      apply_type:      @employee.labor_relation.try(:display_name),
      start_date:      params[:start_date],
      end_date:        params[:end_date],
      note:            params[:note]
    )

    render template: 'api/agreements/show'
  end

  def update
    @agreement = Agreement.find(params[:id])

    if @agreement.update(update_params)
      render json: {messages: '合同更新成功'}
    else
      render json: {messages: @agreement.errors.values.flatten.join(",")}, status: 400
    end

  end

  private
  def update_params
    params.require(:agreement).permit(:start_date, :end_date, :note)
  end
end

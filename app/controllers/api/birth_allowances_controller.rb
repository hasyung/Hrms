class Api::BirthAllowancesController < ApplicationController
  def index
    result = parse_query_params!('birth_allowance')

    render json: {messages: result[:error]}, status: 400 and return unless result[:error].blank?
    relations, conditions, sorts, page = result.values

    @birth_allowances = BirthAllowance.joins(relations).order(sorts)

    conditions.each do |condition|
      @birth_allowances = @birth_allowances.where(condition)
    end

    @birth_allowances = set_page_meta @birth_allowances, page
  end

  def create
    hash = birth_allowance_params
    @birth_allowance = BirthAllowance.new(hash)

    if @birth_allowance.save
      render json: {messages: "发放记录创建成功"}
    else
      render json: {messages: @birth_allowance.errors.full_messages}, status: 400
    end
  end

  def update
    @birth_allowance = BirthAllowance.find_by(params[:id])

    if @birth_allowance.update(birth_allowance_params)
      render json: {messages: "发放记录更新成功"}
    else
      render json: {messages: @birth_allowance.errors.full_messages}, status: 400
    end
  end

  private

  def birth_allowance_params
    params.require(:birth_allowance).permit(:employee_id, :employee_no, :employee_name, :department_name, :position_name, :sent_date, :sent_amount, :deduct_amount)
  end
end

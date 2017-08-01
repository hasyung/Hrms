class Api::SecurityFeesController < ApplicationController

  def index
    result = parse_query_params!('security_fee')
    render json: {messages: result[:error]}, status: 400 and return unless result[:error].blank?
    relations, conditions, sorts, page = result.values

    @security_fees = SecurityFee.joins(employee: :department).joins(relations).order(
      "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no"
    ).order(sorts)

    conditions.each do |condition|
      @security_fees = @security_fees.where(condition)
    end

    @security_fees = set_page_meta @security_fees, page
  end

  def update
    @security_fee = SecurityFee.find(params[:id])

    if @security_fee.update(security_fee_params)
      render template: '/api/security_fees/show'
    else
      return render json: {messages: '修改失败'}, status: 400
    end
  end

  private
  def security_fee_params
    params.permit(:add_garnishee, :remark)
  end
end

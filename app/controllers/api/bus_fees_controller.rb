class Api::BusFeesController < ApplicationController

  def index
    result = parse_query_params!('bus_fee')
    render json: {messages: result[:error]}, status: 400 and return unless result[:error].blank?
    relations, conditions, sorts, page = result.values

    @bus_fees = BusFee.joins(employee: [:department, :channel]).joins(relations).order(
      "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no"
    ).order(sorts)

    conditions.each do |condition|
      @bus_fees = @bus_fees.where(condition)
    end

    @bus_fees = set_page_meta @bus_fees, page
  end

  def compute
    unless params[:month]
      Notification.send_system_message(current_employee.id, {error_messages: '月份不能为空'})
      return render text: ''
    end
    
    is_success, messages = BusFee.compute(params[:month])
    return render json: {bus_fees: [], messages: messages || "计算发生错误"}, status: 400 if !is_success

    @bus_fees = BusFee.joins(employee: [:department, :channel]).order(
      "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no"
      ).where("bus_fees.month = '#{params[:month]}'")
    page = parse_query_params!("bus_fee").values.last
    @bus_fees = set_page_meta(@bus_fees, page)

    render template: 'api/bus_fees/index'
  end

  def import
    attachment = Attachment.find_by(id: params[:attachment_id])

    if %w(xls xlsx).exclude?(attachment.file_type.downcase)
      return render json: {messages: "对不起，目前仅支持xls和xlsx文件导入"}, status: 400
    end

    if attachment.blank?
      return render json: {messages: "参数错误"}, status: 400
    else
      message = Excel::BusFeeImporter.import(attachment.file.url)
      render json: message
    end
  end

  def update
    @bus_fee = BusFee.find(params[:id])

    if @bus_fee.update(bus_fee_params)
      render template: '/api/bus_fees/show'
    else
      render json: {messages: '修改失败'}, status: 400
    end
  end

  private
  def bus_fee_params
    params.permit(:add_garnishee, :remark)
  end
end

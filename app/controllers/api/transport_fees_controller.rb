class Api::TransportFeesController < ApplicationController
  def index
    result = parse_query_params!('transport_fee')
    render json: {messages: result[:error]}, status: 400 and return unless result[:error].blank?
    relations, conditions, sorts, page = result.values

    @transport_fees = TransportFee.joins(employee: :department).joins(relations).order(sorts).order(
      "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no"
    )

    conditions.each do |condition|
      @transport_fees = @transport_fees.where(condition)
    end

    @transport_fees = set_page_meta @transport_fees, page
  end

  def export_nc
    # 文档格式 http://code.cdavatar.com:8083/folders/121
    if params[:month]
      # TODO 只筛选合同制???
      @transport_fees = TransportFee.where(month: params[:month])
      @filename = "交通费合同制导NC.xls"
      @file_path = "#{Rails.root.to_s}/public/export/tmp/#{@filename}"
      Excel::TransportFeeWriter.new(@transport_fees, @file_path).write_nc_excel
      send_file(@file_path, filename: @filename)
    else
      Notification.send_system_message(current_employee.id, {error_messages: '导出月份是必须的参数'})
      return render text: ''
    end
  end

  def export_approval
    if params[:month]
      @transport_fees = TransportFee.where(month: params[:month])
      @filename = "交通费_#{params[:month]}_审批表.xls"
      @file_path = "#{Rails.root.to_s}/public/export/tmp/#{@filename}"
      Excel::TransportFeeWriter.new(@transport_fees, @file_path).write_approval_excel
      send_file(@file_path, filename: @filename)
    else
      Notification.send_system_message(current_employee.id, {error_messages: '导出月份是必须的参数'})
      return render text: ''
    end
  end

  def update
    @transport_fee = TransportFee.find(params[:id])

    if @transport_fee.update(transport_fee_params)
      render template: '/api/transport_fees/show'
    else
      render json: {messages: '修改失败', reason: @transport_fee.errors.full_messages}, status: 400
    end
  end

  def compute
    if params[:month]
      message = SalaryPersonSetup.check_compute(params[:month])
      return render json: {transport_fees: [], messages: message} if message

      is_success, messages = TransportFee.compute(params[:month])
      return render json: {transport_fees: [], messages: messages || "计算发生错误"}, status: 400 if !is_success

      @transport_fees = TransportFee.joins(employee: :department).order(
        "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no"
      ).where("transport_fees.month = '#{params[:month]}'")

      page = parse_query_params!("transport_fee").values.last
      @transport_fees = set_page_meta(@transport_fees, page)

      render template: 'api/transport_fees/index'
    else
      render json: {messages: "计算月份是必须的参数"}, status: 400
    end
  end

  private

  def transport_fee_params
    params.permit(:add_garnishee, :remark)
  end
end

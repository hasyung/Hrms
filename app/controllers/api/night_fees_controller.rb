class Api::NightFeesController < ApplicationController
  def index
    if params[:month]
      @night_fees = NightFee.joins("LEFT JOIN employees ON employees.id=night_fees.employee_id").joins("LEFT JOIN departments ON departments.id=employees.department_id").joins("LEFT JOIN employee_positions ON employee_positions.employee_id=employees.id WHERE employee_positions.category='主职' AND night_fees.month = '#{params[:month]}'")

      page = parse_query_params!("night_fee").values.last
      @night_fees = set_page_meta(@night_fees, page)

      render template: 'api/night_fees/index'
    else
      render json: {messages: "计算月份是必须的参数"}, status: 400
    end
  end

  def update
    @night_fee = NightFee.find(params[:id])

    @night_fee.night_number = params[:night_number].to_i
    @night_fee.is_invalid = @night_fee.check_invalid()
    @night_fee.amount = @night_fee.subsidy.to_f * params[:night_number]
    @night_fee.save

    render template: 'api/night_fees/show'
  end

  def import
    attachment = Attachment.find_by(id: params[:attachment_id])

    if %w(xls xlsx).exclude?(attachment.file_type.downcase)
      return render json: {messages: "对不起，目前仅支持xls和xlsx文件导入"}, status: 400
    end

    if attachment.blank? || params[:month].blank?
      return render json: {messages: "参数错误"}, status: 400
    else
      Excel::NightFeeImporter.import(attachment.file.url, params[:month])
      render json: {messages: '夜餐费数据导入并且计算成功'}
    end
  end

  def compute
    if params[:month]
      is_success, messages = NightFee.compute(params[:month])
      return render json: {night_fees: [], messages: messages || "计算发生错误"}, status: 400 if !is_success

      @night_fees = NightFee.joins("LEFT JOIN employees ON employees.id=night_fees.employee_id").joins("LEFT JOIN departments ON departments.id=employees.department_id").joins("LEFT JOIN employee_positions ON employee_positions.employee_id=employees.id WHERE employee_positions.category='主职' AND night_fees.month = '#{params[:month]}'")

      page = parse_query_params!("night_fee").values.last
      @night_fees = set_page_meta(@night_fees, page)

      render template: 'api/night_fees/index'
    else
      render json: {messages: "计算月份和类型是必须的参数"}, status: 400
    end
  end

  def export
    if params[:type]
      @filename = "#{params[:type]}.xls"
      @file_path = "#{Rails.root.to_s}/public/export/tmp/#{@filename}"
      Excel::NightFeeWriter.send(NightFee::EXPORTOR_TYPE[params[:type]], params[:month], @file_path)
      send_file(@file_path, filename: @filename)
    else
      Notification.send_system_message(current_employee.id, {error_messages: '导出表类型是必须的参数'})
      return render text: ''
    end
  end
end

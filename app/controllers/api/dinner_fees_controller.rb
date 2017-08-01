class Api::DinnerFeesController < ApplicationController
  def index
    if params[:month]
      @dinner_fees = DinnerFee.joins("LEFT JOIN employees ON employees.id=dinner_fees.employee_id").joins("LEFT JOIN departments ON departments.id=employees.department_id").joins("LEFT JOIN employee_positions ON employee_positions.employee_id=employees.id WHERE employee_positions.category='主职' AND dinner_fees.month = '#{params[:month]}'")

      page = parse_query_params!("dinner_fee").values.last
      @dinner_fees = set_page_meta(@dinner_fees, page)

      render template: 'api/dinner_fees/index'
    else
      render json: {messages: "计算月份是必须的参数"}, status: 400
    end
  end

  def compute
    if params[:month] && params[:type]
      is_success, messages = DinnerFee.compute(params[:month], params[:type])
      return render json: {dinner_fees: [], messages: messages || "计算发生错误"}, status: 400 if !is_success

      @dinner_fees = DinnerFee.joins("LEFT JOIN employees ON employees.id=dinner_fees.employee_id").joins("LEFT JOIN departments ON departments.id=employees.department_id").joins("LEFT JOIN employee_positions ON employee_positions.employee_id=employees.id WHERE employee_positions.category='主职' AND dinner_fees.month = '#{params[:month]}'")

      page = parse_query_params!("dinner_fee").values.last
      @dinner_fees = set_page_meta(@dinner_fees, page)

      render template: 'api/dinner_fees/index'
    else
      render json: {messages: "计算月份和类型是必须的参数"}, status: 400
    end
  end

  def import
    attachment = Attachment.find_by(id: params[:attachment_id])

    if %w(xls xlsx).exclude?(attachment.file_type.downcase)
      return render json: {messages: "对不起，目前仅支持xls和xlsx文件导入"}, status: 400
    end

    if attachment.blank? || params[:month].blank? || params[:type].blank? || DinnerFee::IMPORTOR_TYPE[params[:type]].blank?
      return render json: {messages: "参数错误"}, status: 400
    else
      @array = Excel::DinnerFeeImporter.send(DinnerFee::IMPORTOR_TYPE[params[:type]], attachment.file.url, params[:month])
      @array.each do |hash|
        @backup_fee = hash.delete(:amount)
        dinner_fee = DinnerFee.find_by(hash)
        dinner_fee.update(backup_fee: @backup_fee) if dinner_fee
      end

      render json: {messages: '备份餐数据导入并且计算成功'}
    end
  end

  def export
    if params[:type]
      @filename = "#{params[:type]}.xls"
      @file_path = "#{Rails.root.to_s}/public/export/tmp/#{@filename}"
      Excel::DinnerFeeWriter.send(DinnerFee::EXPORTOR_TYPE[params[:type]], params[:month], @file_path)
      send_file(@file_path, filename: @filename)
    else
      Notification.send_system_message(current_employee.id, {error_messages: '导出表类型是必须的参数'})
      return render text: ''
    end
  end
end

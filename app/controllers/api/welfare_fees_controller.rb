class Api::WelfareFeesController <ApplicationController

	def index
    welfare_fees = WelfareFee.where("month like '#{params[:year]}-%'")
    fees = welfare_fees.group_by{|welfare| welfare.category}.to_a.inject({}){|hash, arr| hash.merge!({
    	arr[0] => arr[1].sort{|x, y| x.month <=> y.month}.inject({}){|h, w| h.merge!({w.month
    	.sub("#{params[:year]}-", "").to_i => w.fee})}})} unless welfare_fees.blank?
    fees ||= {}
    render json: {welfare_fees: fees}
  end

  def  import_budget
    attachment = Attachment.find_by(id: params[:attachment_id])

    if attachment.blank?
      return render json: {messages: "参数错误"}, status: 400
    end

    if attachment.blank? || %w(xls xlsx).exclude?(attachment.file_type.downcase)
      return render json: {messages: "对不起，目前仅支持xls和xlsx文件导入"}, status: 400
    end
    message = Excel::WelfareBudgetImportor.import(attachment.file.url)
    render json: {messages: message}

  end

  def getcategory_with_year

    welfare_fees = WelfareFee.where("month like '#{params[:year]}-%'").where(category: params[:category])

    welfare_budgets = WelfareBudget.where(year: params[:year]).where(category: params[:category])

    if welfare_budgets.blank?
      return render json: {message: '当年的预算没有导入'} , status: 400
    end
    remain = welfare_budgets[0].fee
    fees = {}

    welfare_fees.each do |welfare_fee|
      fees[welfare_fee.month] = welfare_fee.fee
      remain -= welfare_fee.fee
    end

    fees['剩余'] = remain
    render json: {welfare_fees: fees}

  end


  def import
    attachment = Attachment.find_by(id: params[:attachment_id])

    if %w(xls xlsx).exclude?(attachment.file_type.downcase)
      return render json: {messages: "对不起，目前仅支持xls和xlsx文件导入"}, status: 400
    end

    if attachment.blank?
      return render json: {messages: "参数错误"}, status: 400
    else
      message = Excel::WelfareFeeImportor.import(attachment.file.url)
      render json: {messages: message}
    end
  end

  def export
    welfare_fees = WelfareFee.where("month like '#{params[:year]}-%'")

    if welfare_fees.blank?
      Notification.send_system_message(current_employee.id, {error_messages: '导出数据为空'})
      return render text: ''
    end
    excel = Excel::WelfareFeeExportor.export(welfare_fees, params[:year])
    send_file(excel[:path], filename: excel[:filename])
  end

end
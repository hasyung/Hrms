class Api::HoursFeesController < ApplicationController
  before_action :check_month, only: [:compute]

  def index
    result = parse_query_params!('hours_fee')
    render json: {messages: result[:error]}, status: 400 and return unless result[:error].blank?
    relations, conditions, sorts, page = result.values

    @hours_fees = HoursFee.joins(employee: :department).joins(relations).order(
      "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no"
    ).order(sorts)

    conditions.each do |condition|
      @hours_fees = @hours_fees.where(condition)
    end

    @hours_fees = set_page_meta @hours_fees, page
  end

  def compute
    message = SalaryPersonSetup.check_compute(params[:month])
    return render json: {basic_salaries: [], messages: message} if message

    is_success, messages = HoursFee.compute(params[:month], params[:hours_fee_category])
    return render json: {hours_fees: [], messages: messages || "计算发生错误"}, status: 400 if !is_success

    @hours_fees = HoursFee.joins(employee: :department).order(
      "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no"
    ).where("hours_fees.month = '#{params[:month]}' and hours_fees.hours_fee_category = '#{params[:hours_fee_category]}'")
    page = parse_query_params!("hours_fee").values.last
    @hours_fees = set_page_meta(@hours_fees, page)

    render template: 'api/hours_fees/index'
  end

  def import
    attachment = Attachment.find_by(id: params[:attachment_id])

    if %w(xls xlsx).exclude?(attachment.file_type.downcase)
      return render json: {messages: "对不起，目前仅支持xls和xlsx文件导入"}, status: 400
    end

    if attachment.blank? || params[:month].blank? || params[:type].blank? || HoursFee::IMPORTOR_TYPE[params[:type]].blank?
      return render json: {messages: "参数错误"}, status: 400
    else
      message = Excel::HoursFeeImporter.send(HoursFee::IMPORTOR_TYPE[params[:type]], attachment.file.url, params[:month])
      render json: message
    end
  end

  def import_add_garnishee
    attachment = Attachment.find_by(id: params[:attachment_id])

    if %w(xls xlsx).exclude?(attachment.file_type.downcase)
      return render json: {messages: "对不起，目前仅支持xls和xlsx文件导入"}, status: 400
    end

    if attachment.blank? || params[:month].blank? || params[:hours_fee_category].blank?
      return render json: {messages: "参数错误"}, status: 400
    else
      message = Excel::HoursFeeImporter.import_add_garnishee(attachment.file.url, params[:month], params[:hours_fee_category])
      render json: message
    end
  end

  def import_refund_fee
    attachment = Attachment.find_by(id: params[:attachment_id])

    if %w(xls xlsx).exclude?(attachment.file_type.downcase)
      return render json: {messages: "对不起，目前仅支持xls和xlsx文件导入"}, status: 400
    end

    if attachment.blank? || params[:month].blank? || params[:hours_fee_category].blank?
      return render json: {messages: "参数错误"}, status: 400
    else
      message = Excel::HoursFeeImporter.import_refund_fee(attachment.file.url, params[:month], params[:hours_fee_category])
      render json: message
    end
  end

  def export_nc
    if(params[:month])
      salaries = HoursFee.joins(employee: :department).order(
        "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no"
        ).where("hours_fees.month = '#{params[:month]}'")
      if salaries.blank?
        Notification.send_system_message(current_employee.id, {error_messages: '导出数据为空'})
        return render text: ''
      end
      excel = Excel::HoursFeeExportor.export_nc(salaries, params[:month])
      send_file(excel[:path], filename: excel[:filename])
    else
      Notification.send_system_message(current_employee.id, {error_messages: '条件不足'})
      return render text: ''
    end
  end

  def export_approval
    if(params[:month])
      excel = Excel::HoursFeeExportor.export_approval(params[:month])
      send_file(excel[:path], filename: excel[:filename])
    else
      Notification.send_system_message(current_employee.id, {error_messages: '条件不足'})
      return render text: ''
    end
  end

  def update
    @hours_fee = HoursFee.find(params[:id])
    @hours_fee.assign_attributes(hours_fee_params)

    channel = CodeTable::Channel.find_by(id: @hours_fee.channel_id).try(:display_name)
    hours_fees = HoursFee.where(employee_id: @hours_fee.employee_id, month: @hours_fee.month)

    is_deduce = 0
    if channel == '空勤' && @hours_fee.add_garnishee_changed? && (hours_fees.size == 1 || 
      @hours_fee.hours_fee_category == '安全员') && @hours_fee.fly_fee
      is_deduce = 1
      if @hours_fee.airline_fee.to_f > 0
        if @hours_fee.fly_fee.to_f + @hours_fee.add_garnishee.to_f >= 0 && @hours_fee.employee.salary_person_setup.is_send_airline_fee
          is_deduce = 2
        else
          @hours_fee.fly_fee += @hours_fee.airline_fee
          @hours_fee.total = @hours_fee.fly_fee + @hours_fee.fertility_allowance.to_f
          @hours_fee.airline_fee = 0
        end
      else
        fly_hours = hours_fees.map(&:fly_hours).map(&:to_f).inject(:+).to_f
        if %w(领导 干部).include?(@hours_fee.employee.category.try(:display_name))
          @hours_fee.airline_fee = 912.5 if fly_hours > 0
        else
          @hours_fee.airline_fee = fly_hours*10 > 912.5 ? 912.5 : fly_hours*10
        end

        if fly_hours > 0 && @hours_fee.fly_fee.to_f + @hours_fee.add_garnishee.to_f >= @hours_fee.airline_fee && @hours_fee.employee.salary_person_setup.is_send_airline_fee
          @hours_fee.fly_fee -= @hours_fee.airline_fee
          @hours_fee.total = @hours_fee.fly_fee + @hours_fee.fertility_allowance.to_f
          is_deduce = 2
        end
      end
    end

    if @hours_fee.save
      calc_steps = CalcStep.where(employee_id: @hours_fee.employee_id, month: @hours_fee.month).where(
        "category='hours_fee/security' or category='hours_fee/service'")
      calc_step = calc_steps.first
      if is_deduce == 2
        calc_steps.update_all(step_notes: calc_step.push_step("#{calc_step.step_notes.size + 1}. " + 
          "补扣发修改为: #{@hours_fee.add_garnishee}, 需在小时费中扣除空勤灶"), amount: @hours_fee.total)
      elsif is_deduce == 1
        calc_steps.update_all(step_notes: calc_step.push_step("#{calc_step.step_notes.size + 1}. " + 
          "补扣发修改为: #{@hours_fee.add_garnishee}, 因薪酬个人设置不发放空勤灶、小时费不足或本月无飞行时间不扣除空勤灶, 无空勤灶"), amount: @hours_fee.total)
      end
        
      render template: '/api/hours_fees/show'
    else
      render json: {messages: '修改失败'}, status: 400
    end
  end

  private
  def hours_fee_params
    params.permit(:add_garnishee, :remark, :airline_fee)
  end

  def check_month
    if params[:month].blank? || params[:hours_fee_category].blank?
      Notification.send_system_message(current_employee.id, {error_messages: '月份或人员类别不能为空'})
      return render text: ''
    end
  end
end

class Api::AllowancesController < ApplicationController
  include ExceptionHandler

  def compute
    if params[:month]
      message = SalaryPersonSetup.check_compute(params[:month])
      return render json: {allowances: [], messages: message} if message

      is_success, messages = Allowance.compute(params[:month])
      return render json: {allowances: [], messages: messages || "计算发生错误"}, status: 400 if !is_success

      @allowances = Allowance.joins(employee: :department).order(
        "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no"
        ).where("allowances.month = '#{params[:month]}'")
      page = parse_query_params!("allowance").values.last

      @allowances = set_page_meta(@allowances, page)
      render template: 'api/allowances/index'
    else
      render json: {messages: "条件不足"}, status: 400
    end
  end

  def index
    result = parse_query_params!('allowance')

    render json: {messages: result[:error]}, status: 400 and return unless result[:error].blank?
    relations, conditions, sorts, page = result.values

    @allowances = Allowance.joins(employee: :department).joins(relations).order(
      "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no"
    ).order(sorts)

    conditions.each do |condition|
      @allowances = @allowances.where(condition)
    end

    @allowances = set_page_meta @allowances, page
  end

  def update
    @allowance = Allowance.find(params[:id])

    if @allowance.update(allowance_params)
      render template: '/api/allowances/show'
    else
      render json: {messages: '修改失败'}, status: 400
    end
  end

  def import
    attachment = Attachment.find_by(id: params[:attachment_id])

    if %w(xls xlsx).exclude?(attachment.file_type.downcase)
      return render json: {messages: "对不起，目前仅支持xls和xlsx文件导入"}, status: 400
    end

    if attachment.blank? || params[:month].blank? || params[:type].blank? || Allowance::IMPORTOR_TYPE[params[:type]].blank?
      return render json: {messages: "参数错误"}, status: 400
    else
      message = Excel::AllowanceImporter.send(Allowance::IMPORTOR_TYPE[params[:type]], attachment.file.url, params[:month])
      render json: message
    end
  end

  def export_nc
    export_subsidy :nc
  end

  def export_temp
    if params[:month]
      @allowances = Allowance.where(month: params[:month]).where("temp > 0")
      @filename = "高温津贴表.xls"
      @file_path = "#{Rails.root.to_s}/public/export/tmp/#{@filename}"
      Excel::AllowanceWriter.new(@allowances, @file_path).write_temp
      send_file(@file_path, filename: @filename)
    else
      Notification.send_system_message(current_employee.id, {error_messages: '导出月份是必须的参数'})
      render text: ''
    end
  end

  def export_land_present
    export_subsidy :land_present
  end

  def export_car_present
    export_subsidy :car_present
  end

  def export_permit_entry
    export_subsidy :permit_entry
  end

  def export_security_check
    export_subsidy :security_check
  end

  def export_fly_honor
    export_subsidy :fly_honor
  end

  def export_communication
    export_subsidy :communication
  end

  def export_resettlement
    export_subsidy :resettlement
  end

  def export_group_leader
    export_subsidy :group_leader
  end

  def export_communication_nc
    export_subsidy :communication_nc
  end

  def export_subsidy(name)
    if(params[:month])
      allowances = Allowance.joins(employee: :department)
        .includes(employee: [:labor_relation, :channel, :duty_rank]).order(
        "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no"
        ).where("allowances.month = '#{params[:month]}'")
      if allowances.blank?
        Notification.send_system_message(current_employee.id, {error_messages: '导出数据为空'})
        return render text: ''
      end
      excel = Excel::AllowanceExportor.send("export_#{name}", allowances, params[:month])
      send_file(excel[:path], filename: excel[:filename])
    else
      Notification.send_system_message(current_employee.id, {error_messages: '条件不足'})
      render text: ''
    end
  end


  private
  def allowance_params
    params.permit(:add_garnishee, :remark)
  end

end

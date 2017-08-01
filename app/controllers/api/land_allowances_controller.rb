class Api::LandAllowancesController < ApplicationController

  def index
    result = parse_query_params!('land_allowance')
    render json: {messages: result[:error]}, status: 400 and return unless result[:error].blank?
    relations, conditions, sorts, page = result.values

    @land_allowances = LandAllowance.joins(employee: [:department, :channel]).joins(relations).order(
      "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no"
    ).order(sorts)

    if params[:type] == '空勤'
      @land_allowances = @land_allowances.where("code_table_channels.display_name in (?)", %w(空勤 飞行))
    elsif params[:type] == '地面'
      @land_allowances = @land_allowances.where("code_table_channels.display_name not in (?)", %w(空勤 飞行))
    end

    conditions.each do |condition|
      @land_allowances = @land_allowances.where(condition)
    end

    @land_allowances = set_page_meta @land_allowances, page
  end

  def compute
    if params[:month] && params[:type]
      message = SalaryPersonSetup.check_compute(params[:month])
      return render json: {land_allowances: [], messages: message} if message

      if params[:type] == '空勤'
        is_success, messages = LandAllowance.compute_service(params[:month])
        return render json: {land_allowances: [], messages: messages || "计算发生错误"}, status: 400 if !is_success

        @land_allowances = LandAllowance.joins(employee: [:department, :channel]).order(
          "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no"
        ).where("land_allowances.month = '#{params[:month]}' and code_table_channels.display_name in (?)", 
        %w(空勤 飞行))
      elsif params[:type] == '地面'
        is_success, messages = LandAllowance.compute_land(params[:month])
        return render json: {land_allowances: [], messages: messages || "计算发生错误"}, status: 400 if !is_success

        @land_allowances = LandAllowance.joins(employee: [:department, :channel]).order(
          "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no"
        ).where("land_allowances.month = '#{params[:month]}' and code_table_channels.display_name not in (?)", 
        %w(空勤 飞行))
      else
        return render json: {messages: "类型错误"}, status: 400
      end
      page = parse_query_params!("land_allowance").values.last
      @land_allowances = set_page_meta(@land_allowances, page)
      render template: 'api/land_allowances/index'
    else
      render json: {messages: "计算月份和类型是必须的参数"}, status: 400
    end
  end

  def import
    attachment = Attachment.find_by(id: params[:attachment_id])

    if %w(xls xlsx).exclude?(attachment.file_type.downcase)
      return render json: {messages: "对不起，目前仅支持xls和xlsx文件导入"}, status: 400
    end

    if attachment.blank? || params[:month].blank? || params[:type].blank? || LandAllowance::IMPORTOR_TYPE[params[:type]].blank?
      return render json: {messages: "参数错误"}, status: 400
    else
      message = Excel::LandAllowanceImporter.send(LandAllowance::IMPORTOR_TYPE[params[:type]], params[:type], attachment.file.url, params[:month])
      render json: message
    end
  end

  def export_nc
    if(params[:month])
      land_allowances = LandAllowance.joins(employee: :department).order(
        "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no"
        ).where("land_allowances.month = '#{params[:month]}'")
      if land_allowances.blank?
        Notification.send_system_message(current_employee.id, {error_messages: '导出数据为空'})
        return render text: ''
      end
      excel = Excel::LandAllowanceExportor.export_nc(land_allowances, params[:month])
      send_file(excel[:path], filename: excel[:filename])
    else
      Notification.send_system_message(current_employee.id, {error_messages: '条件不足'})
      render text: ''
    end
  end

  def export_approval
    if(params[:month])
      land_allowances = LandAllowance.joins(employee: [:department, :channel])
        .includes(employee: [:labor_relation, :channel]).order(
        "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no"
        ).where("land_allowances.month = '#{params[:month]}' and code_table_channels.display_name != '空勤' 
        and code_table_channels.display_name != '飞行'")
      if land_allowances.blank?
        Notification.send_system_message(current_employee.id, {error_messages: '导出数据为空'})
        return render text: ''
      end
      excel = Excel::LandAllowanceExportor.export_approval(land_allowances, params[:month])
      send_file(excel[:path], filename: excel[:filename])
    else
      Notification.send_system_message(current_employee.id, {error_messages: '条件不足'})
      render text: ''
    end
  end

  def update
    @land_allowance = LandAllowance.find(params[:id])

    if @land_allowance.update(land_allowance_params)
      render template: '/api/land_allowances/show'
    else
      render json: {messages: '修改失败'}, status: 400
    end
  end

  private
  def land_allowance_params
    params.permit(:add_garnishee, :remark)
  end
end

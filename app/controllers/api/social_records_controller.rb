class Api::SocialRecordsController < ApplicationController
  include ExceptionHandler

  def import
    attachment = Attachment.find(params[:attachment_id])
    if %w(xls xlsx).exclude?(attachment.file_type.downcase)
      return render json: {messages: "对不起，目前仅支持xls和xlsx文件导入"}, status: 400
    end
    if attachment.blank? or params[:month].blank?
      return render json: {messages: "参数错误"}, status: 400
    end
    importer = Excel::SocialCardinalityImporter.new(attachment.file.url, params[:month]) 
    # message = Excel::SocialCardinalityImporter.import(attachment.file.url, params[:month])
    message = importer.import
    render json: message
  end

  def compute
    if params[:month]
      message = SocialRecord.check_compute(params[:month])
      return render json: {social_records: [], messages: message} if message

      SocialRecord.compute(params[:month])
      @social_records = SocialRecord.joins(employee: :department).order(
        "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no"
        ).where("social_records.compute_month = '#{params[:month]}'")
      page = parse_query_params!("social_record").values.last
      @social_records = set_page_meta(@social_records, page)
      render template: 'api/social_records/index'
    else
      render json: {messages: "条件不足"}, status: 400
    end
  end

  def export_record
    if(params[:month])
      social_records = SocialRecord.includes(employee: :labor_relation)
        .joins(employee: :department).order(
        "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no")
        .where("compute_month = '#{params[:month]}' and social_location = '成都' 
        and employees.classification != '空警'")
      if social_records.blank?
        Notification.send_system_message(current_employee.id, {error_messages: '导出数据为空'})
        return render text: ''
      end
      excel = Excel::SocialRecordExporter.export_record(social_records)
      send_file(excel[:path], filename: excel[:filename])
    else
      Notification.send_system_message(current_employee.id, {error_messages: '条件不足'})
      render text: ''
    end
  end

  def export_declare
    if(params[:month])
      social_records = SocialRecord.joins(employee: :department).order(
        "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no")
        .where("compute_month = '#{params[:month]}'")
      if social_records.blank?
        Notification.send_system_message(current_employee.id, {error_messages: '导出数据为空'})
        return render text: ''
      end
      excel = Excel::SocialRecordExporter.export_declare(social_records)
      send_file(excel[:path], filename: excel[:filename])
    else
      Notification.send_system_message(current_employee.id, {error_messages: '条件不足'})
      render text: ''
    end
  end

  def export_withhold
    if(params[:month])
      records = SocialRecord.joins(employee: :department).order(
        "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no")
        .where("social_records.compute_month = '#{params[:month]}' and departments.name != '商旅公司' 
        and departments.name != '文化传媒广告公司' and departments.name != '校修中心' and 
        employees.classification != '空警'")
      if records.blank?
        Notification.send_system_message(current_employee.id, {error_messages: '导出数据为空'})
        return render text: ''
      end

      shanglv = SocialRecord.joins(employee: :department)
        .where("social_records.compute_month = '#{params[:month]}' and departments.name = '商旅公司'")
      guanggao = SocialRecord.joins(employee: :department)
        .where("social_records.compute_month = '#{params[:month]}' and departments.name = '文化传媒广告公司'")
      xiaoxiu = SocialRecord.joins(employee: :department)
        .where("social_records.compute_month = '#{params[:month]}' and departments.name = '校修中心'")
      gongwu = SocialRecord.joins(:employee)
        .where("social_records.compute_month = '#{params[:month]}' and employees.classification = '空警'")

      excel = Excel::SocialRecordExporter.export_withhold([records, shanglv, xiaoxiu, guanggao, gongwu])
      send_file(excel[:path], filename: excel[:filename])
    else
      Notification.send_system_message(current_employee.id, {error_messages: '条件不足'})
      render text: ''
    end
  end

  def index
    result = parse_query_params!('social_record')
    render json: {messages: result[:error]}, status: 400 and return unless result[:error].blank?
    relations, conditions, sorts, page = result.values

    @social_records = SocialRecord.joins(employee: :department).joins(relations).order(
      "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no"
    ).order(sorts)

    conditions.each do |condition|
      @social_records = @social_records.where(condition)
    end
    @social_records = set_page_meta @social_records, page
  end
end

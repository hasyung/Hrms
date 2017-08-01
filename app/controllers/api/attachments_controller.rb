class Api::AttachmentsController < ApplicationController
  include ExceptionHandler
  skip_before_action :check_action_register
  skip_before_action :check_permission

  def upload_xls
    @attachment = Attachment.new(file: params[:file], employee_id: current_employee.id)

    if @attachment.valid? && Setting.upload_excel_extension.include?(@attachment.file_extension.downcase)
      @attachment.save
      render json: @attachment
    else
      render json: {messages: "上传的文件不正确, 系统只支持#{Setting.upload_excel_extension.join(',')}两种格式"}, status: 400
    end
  end

  def upload_image
    @attachment = Attachment.new(file: params[:file], employee_id: current_employee.id)

    if @attachment.valid? && Setting.upload_image_extension.include?(@attachment.file_extension.downcase)
      @attachment.save
      render json: @attachment
    else
      render json: {messages: "上传的文件不正确, 系统只支持#{Setting.upload_image_extension.join(',')}格式"}, status: 400
    end
  end

  def upload_doc
    #
  end

  def upload_file
    @attachment = Attachment.new(file: params[:file], employee_id: current_employee.id)

    if @attachment.valid? && @attachment.save
      render json: @attachment
    else
      render json: {messages: "上传文件错误, 系统不支持上传#{Setting.upload_attachment_extension.join(',')}格式"}, status: 400
    end
  end

  def report_upload_file
    @attachment = Attachment.new(file: params[:file], employee_id: current_employee.id)

    if @attachment.valid? && @attachment.save
      render template: '/api/attachments/report_attachment'
    else
      render json: {messages: "上传文件错误, 系统不支持上传#{Setting.upload_attachment_extension.join(',')}格式"}, status: 400
    end
  end
end

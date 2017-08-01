class Api::PerformanceAttachmentsController < ApplicationController
  include ExceptionHandler

  def create
    @attachment  = Attachment.find params[:id]
    @performance = Performance.find params[:performance_id]

    if @performance.present? && @attachment.present?
      @attachment.attachmentable = @performance
      @attachment.save
      @attachments = @performance.attachments
      render template: 'api/performance_attachments/show'
    else
      render json: {messages: '参数错误, 资源不存在'}, status: 400
    end
  end

  def show
    @performance = Performance.find params[:performance_id]
    @attachments = @performance.attachments
  end

  def destroy
    @attachment = Attachment.find(params[:id])

    if @attachment.present? && @attachment.employee_id != @current_employee.id
      render json: {messages: '只有上传该附件的人能删除'}, status: 400 and return
    end

    if @attachment.destroy
      render json: {messages: '该附件删除成功'}
    else
      render json: {messages: '参数错误'}, status: 400
    end
  end
end

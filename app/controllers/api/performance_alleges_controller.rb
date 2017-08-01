class Api::PerformanceAllegesController < ApplicationController
  include ExceptionHandler

  def index
    result = parse_query_params!('performance_allege')
    render json: {messages: result[:error]}, status: 400 and return unless result[:error].blank?
    relations, conditions, sorts, page = result.values

    @alleges = PerformanceAllege.joins(performance: :employee).order(sorts)
    conditions.each do |condition|
      @alleges = @alleges.where(condition)
    end

    @alleges = set_page_meta @alleges, page
    render template: '/api/performance_alleges/index'
  end

  def show
    @allege = PerformanceAllege.find(params[:id])
  end

  def create
    performance = Performance.find(params[:performance_id])
    return render json: {messages: '该员工已离职'}, status: 400 unless performance.employee

    if performance.allege.present?
      return render json: {messages: '绩效申述已存在'}, status: 400
    end

    @allege = performance.build_allege params.permit(:reason)
    if @allege.save
      render template: '/api/performance_alleges/show'
    else
      render json: {messages: '参数错误'}, status: 400
    end
  end

  def update
    @allege = PerformanceAllege.find(params[:id])

    if @allege.outcome.present?
      render json: {messages: "该绩效申诉已经处理"}, status: 400 and return
    end

    @allege.assign_attributes(params.permit(:outcome))

    if @allege.valid?
      PerformanceAllege.transaction do
        @allege.performance_was = @allege.performance.result if params[:outcome] == '通过'
        @allege.performance.update(params.permit(:result)) if params[:outcome] == '通过'
        @allege.save
      end

      return render template: '/api/performance_alleges/show'
    else
      return render json: {messages: '参数错误'}, status: 400
    end
  end

  def attachment_create
    @attachment = PerformanceAllege.find(params[:id]).attachments.new params.permit(:file)

    @attachment.employee_id = @current_employee.id
    if @attachment.save
      render template: '/api/performance_alleges/attachment'
    else
      render json: {messages: '参数错误'}, status: 400
    end
  end

  def attachment_destroy
    @attachment = PerformanceAllegeAttachment.find(params[:attachment_id])

    if @attachment.employee_id != @current_employee.id
      return render json: {messages: '只有上传该附件的人能删除'}, status: 400
    end

    if @attachment.destroy
      render json: {messages: '附件删除成功'}
    else
      render json: {messages: '参数错误'}, status: 400
    end
  end

end

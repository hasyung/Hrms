class Api::ReportsController < ApplicationController
  def create
    @report = @current_employee.reports.new(permit_params)
    @report.department_name = @current_employee.department.try(:name)

    if @report.save
      render template: 'api/reports/show'
    else
      render json: {messages: "增加汇报失败"}, status: 400
    end
  end

  def index
    @reports = @current_employee.reports.includes(:attachments, :employee).order(created_at: :desc)
  end

  def update
    @report = Report.includes(:attachments).find params[:id]

    if @report.employee_id != @current_employee.id
      render json: {messages: '权限错误'}, status: 400
    end

    if @report.update(permit_params)
      render template: 'api/reports/show'
    else
      render json: {messages: "更新失败"}, status: 400
    end
  end

  def destroy
    @report = Report.find params[:id]

    if @report.employee_id != @current_employee.id
      render json: {messages: '权限错误'}, status: 400
    end

    if @report.destroy
      render json: {messages: '删除成功'}
    else
      render json: {messages: '删除失败'}, status: 400
    end
  end

  def show
    @report = Report.includes(:attachments).find params[:id]
  end

  def need_to_know
    position_ids = @current_employee.position_ids
    if position_ids.include?(Position.find_by(name: '人力资源部总经理').try(:id))
      @reports = Report.includes(:attachments, :employee).where(department_name: params[:department_name]).order(created_at: :desc)
        .select{ |item| item.checker.include?(Position.find_by(name: '人力资源部总经理').try(:id)) }
    elsif position_ids.include?(Position.find_by(name: '副总经理（人事、劳动关系、招飞）').try(:id))
      @reports = Report.includes(:attachments, :employee).where(department_name: params[:department_name]).order(created_at: :desc)
        .select{ |item| item.checker.include?(Position.find_by(name: '副总经理（人事、劳动关系、招飞）').try(:id)) }
    elsif position_ids.include?(Position.find_by(name: '副总经理（培训、员工服务）').try(:id))
      @reports = Report.includes(:attachments, :employee).where(department_name: params[:department_name]).order(created_at: :desc)
        .select{ |item| item.checker.include?(Position.find_by(name: '副总经理（培训、员工服务）').try(:id)) }
    else
      render json: {messages: '无权限查看汇报消息'}, status: 400 and return
    end
    render template: 'api/reports/index'
  end

  private
  def permit_params
    params.permit(:title, :content, :checker => [], :attachment_ids => [])
  end
end

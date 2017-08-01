class Api::AnnuitiesController < ApplicationController
  include ExceptionHandler

  def index
    result = parse_query_params!('employee')
    render json: {messages: result[:error]}, status: 400 and return unless result[:error].blank?
    relations, conditions, sorts, page = result.values

    @relation = Employee::LaborRelation.where(display_name: '合同制').first

    @employees = Employee.unscoped.includes(
      [:contact, :positions => [:department]]
    ).joins(
      :department
    ).joins(relations).where(
      "employees.labor_relation_id = #{@relation.id}"
    ).order(
      "departments.d1_sort_no,
      departments.d2_sort_no,
      departments.d3_sort_no,
      employees.sort_no"
    )

    conditions.each do |condition|
      @employees = @employees.where(condition)
    end

    @employees = set_page_meta @employees, page
  end

  def show
    redirect_to controller: "employees", action: "show", id: params[:id]
  end

  def update
    @annuity = Employee.find params[:id]

    if @annuity.present? && @annuity.update(annuity_params)
      render json: {messages: '修改成功'}
    else
      render json: {messages: '修改失败'}, status: 400
    end
  end

  def show_cardinality
    employee  = Employee.find params[:employee_id]
    last_year = Date.today.last_year.year
    @records  = SocialRecord.show_record(employee, last_year)
    @records_size = @records.size
    @cardinality = @records_size == 0 ? 0 : (@records.sum(:pension_cardinality) / @records_size).round(2)
  end

  def cal_year_annuity_cardinality
    last_year = Date.today.last_year.year
    Annuity.cal_year_annuity_cardinality(last_year)

    render json: {messages: "计算完成"}
  end

  def cal_annuity
    if Annuity.check_annuity_status
      render json: {messages: '请确认在缴状态人员的年金基数设置', annuities: []} and return
    end

    if params[:date].blank?
      render json: {messages: "计算月份不能为空"}, status: 400 and return
    else
      Annuity.cal_annuity(params[:date])

      @annuities = Annuity.where(cal_date: params[:date])
      page = parse_query_params!("annuity").values.last
      @annuities = set_page_meta @annuities, page

      render template: "api/annuities/list_annuity"
    end
  end

  def export_annuity_to_xls
    @annuities = Annuity.where(cal_date: params[:date])

    if @annuities.present?
      excel = Excel::AnnuityListWriter.export_annuity_to_xls(@annuities)
      send_file(excel[:path], filename: excel[:filename])
    else
      Notification.send_system_message(current_employee.id, {error_messages: '导出数据为空'})
      render text: ''
    end
  end

  #列出当月年金缴纳详情
  def list_annuity
    result = parse_query_params!('annuity')

    render json: {messages: result[:error]}, status: 400 and return unless result[:error].blank?
    relations, conditions, sorts, page = result.values

    @annuities = Annuity.all.order(:cal_date)
    @annuities = Annuity.where(cal_date: params[:date]) if params[:date]

    conditions.each do |condition|
      @annuities = @annuities.where(condition)
    end

    @annuities = set_page_meta @annuities, page
  end

  #导出年金模板到excel
  def export_to_xls
    @relation = Employee::LaborRelation.where(display_name: '合同制').first

    @employees = Employee.unscoped.includes(
      [:contact, :positions => [:department]]
    ).joins(
      :department
    ).where(
      "employees.labor_relation_id = #{@relation.id}"
    ).order(
      "departments.d1_sort_no,
      departments.d2_sort_no,
      departments.d3_sort_no,
      employees.sort_no"
    )

    excel = Excel::AnnuityTempWriter.new(@employees).write_excel
    send_file(excel.path, filename: excel.filename)
  end

  private
  def annuity_params
    params[:annuity_status] = params[:annuity_status] == "在缴" ? true : false
    params.permit(:annuity_cardinality, :annuity_status)
  end
end

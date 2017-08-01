class Api::PerformancesController < ApplicationController
  include ExceptionHandler

  def index
    result = parse_query_params!('performance')
    render json: {messages: result[:error]}, status: 400 and return unless result[:error].blank?

    relations, conditions, sorts, page = result.values

    @performances = Performance.includes(:attachments, :allege).joins(employee: :department).joins(relations).order(
      "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no"
      ).order("performances.assess_time DESC").order(sorts)

    # if current_employee.hr?
      
    # elsif current_employee.department_hr?
    #   @departments_ids = Department.includes(:attachments, :allege).find(FlowRelation.where("position_ids like '%- \\'#{current_employee.master_position.id}\\'\n%'").first.department_id).get_underling_include_self.map(&:id)
    #   @employee_ids = Employee.where(department_id: @departments_ids).map(&:id)
    #   @performances = @performances.where(employee_id: @employee_ids)
    # else
    #   @performances = current_employee.performances.order("performances.assess_time DESC")
    # end

    if !(@current_employee.hr? and !@current_employee.department_hr?) and !@current_employee.company_leader?
      department_ids = @current_employee.get_departments_for_role

      if department_ids.present?
        @employees = @employees.joins(:positions)
          .where("positions.department_id in (?) or employees.id = #{@current_employee.id}", department_ids)
      else
        @employees = @employees.joins(:positions).where("employees.id = #{@current_employee.id}")
      end
    end

    conditions.each do |condition|
      @performances = @performances.where(condition)
    end

    @performances = set_page_meta @performances, page
  end

  #绩效列表
  def index_all
    if params[:department_id]
      get_employees
      @employees = @employees.where(department_id: params[:department_id]).where.not(category: 1).uniq
    else
      result = parse_query_params!('employee')
      render json: {messages: result[:error]}, status: 400 and return unless result[:error].blank?
      relations, conditions, sorts, page = result.values
      get_employees
      @employees = @employees.where("employees.category_id != 1").joins(relations).order(sorts)

      conditions.each do |condition|
        @employees = @employees.where(condition)
      end

      @employees = set_page_meta @employees.uniq, page
    end

    
    @performances = []
    performance = Performance.includes('employee').where(assess_year: params[:year], employee_id: @employees.map(&:id))
    @employees.each do |employee|
      @performances << {employee: employee}

      performance.each do |perfor|
        if perfor.employee_id == employee.id
          @performances.last.merge!(sort_no: perfor.sort_no) if perfor.category == "year"
          @performances.last.merge!(id: perfor.id) if perfor.category == "year"

          @performances.last.merge!(january: perfor.result) if perfor.category == "month" && perfor.assess_time.month == 1
          @performances.last.merge!(february: perfor.result) if perfor.category == "month" && perfor.assess_time.month == 2
          @performances.last.merge!(march: perfor.result) if perfor.category == "month" && perfor.assess_time.month == 3
          @performances.last.merge!(april: perfor.result) if perfor.category == "month" && perfor.assess_time.month == 4
          @performances.last.merge!(may: perfor.result) if perfor.category == "month" && perfor.assess_time.month == 5
          @performances.last.merge!(june: perfor.result) if perfor.category == "month" && perfor.assess_time.month == 6
          @performances.last.merge!(july: perfor.result) if perfor.category == "month" && perfor.assess_time.month == 7
          @performances.last.merge!(august: perfor.result) if perfor.category == "month" && perfor.assess_time.month == 8
          @performances.last.merge!(september: perfor.result) if perfor.category == "month" && perfor.assess_time.month == 9
          @performances.last.merge!(october: perfor.result) if perfor.category == "month" && perfor.assess_time.month == 10
          @performances.last.merge!(november: perfor.result) if perfor.category == "month" && perfor.assess_time.month == 11
          @performances.last.merge!(december: perfor.result) if perfor.category == "month" && perfor.assess_time.month == 12

          @performances.last.merge!(season: perfor.result) if perfor.category == "season"
          @performances.last.merge!(year: perfor.result) if perfor.category == "year"
        end
        

      end
    end
    @performances
  end



  def temp
    result = parse_query_params!('employee')
    render json: {messages: result[:error]}, status: 400 and return unless result[:error].blank?
    relations, conditions, sorts, page = result.values

    @employees = Employee.includes(
      [:job_title_degree, :gender, :political_status,\
       :education_background, :contact, :master_positions,\
       :category, :labor_relation, :channel,\
       :positions => [:department]]
    ).joins(
      "JOIN departments ON departments.id = employees.department_id"
    ).joins(relations).order(
      "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no"
    ).order(sorts)

    conditions.each do |condition|
      @employees = @employees.where(condition)
    end

    @employees = set_page_meta @employees, page
  end

  def update
    @performance = Performance.find(params[:id])
    return render json: {messages: '该员工已离职'}, status: 400 unless @performance.employee

    @performance.update(params.permit(:sort_no))

    render json: @performance
  end

  def update_result
    @performance = Performance.find(params[:id])
    return render json: {messages: '该员工已离职'}, status: 400 unless @performance.employee

    render json: {messages: '只能修改主官的季度考核结果'}, status: 400 and return if @performance.category != 'season'

    @performance.update(result: params[:result])

    render json: @performance
  end

  def update_temp
    @employee_temp = Employee.find_by(id: params[:id])

    unless @employee_temp.present?
      render json: {messages: "没有找到对应模板"}, status: 400 and return
    end

    if @employee_temp.update(temp_params)
      render json: {messages: "修改成功"}
    else
      render json: {messages: "修改失败"}, status: 400
    end
  end

  def temp_export
    except_department_ids = Department.where(name: ["商旅公司","文化传媒广告公司","校修中心"]).map(&:id)
    if current_employee.hr?
      @employee_temps = Employee.includes(
        [
          :duty_rank, :positions => [:department]
        ]
      ).joins(
        "JOIN departments ON departments.id = employees.department_id"
      ).where.not(
        department_id: except_department_ids
      ).order(
        "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no"
      ).all
    elsif current_employee.department_hr?
      @departments_ids = Department.find(FlowRelation.where("position_ids like '%- \\'#{current_employee.master_position.id}\\'\n%'").first.department_id).get_underling_include_self.map(&:id)
      @employee_temps = Employee.includes(
        [
          :duty_rank, :positions => [:department]
        ]
      ).joins(
        "JOIN departments ON departments.id = employees.department_id"
      ).where(
        department_id: @departments_ids
      ).where.not(
        department_id: except_department_ids
      ).order(
        "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no"
      )
    end

    excel = Excel::PerformanceTempWriter.export_temp(@employee_temps)
    send_file(excel[:path], filename: excel[:filename])
  end

  def import_performances
    render json: {messages: "月份不能为空"}, status: 400 and return unless params[:assess_time]
    
    file = Attachment.find(params[:file_id]).full_path
    @performance_importer = Excel::PerformanceImporter.new(file, params[:assess_time], params[:category]).call

    render json: {messages: @performance_importer.messages}
  end

  def import_month_distribute_base
    @month_distribute_base_importer = Excel::MonthDistributeBase.new(params[:file]).call

    render json: {messages: @month_distribute_base_importer.messages}
  end

  def attachments_save
    performance = Performance.find_by(id: params[:id])

    return render json: {messages: '该员工已离职'}, status: 400 unless performance.employee
    if performance.attachments.new(
        file: params[:file],
        employee_id: current_employee.id
    ).save
      @attachments = Performance.find(params[:id]).attachments
      render template: '/api/performance_attachments/show'
    else
      render json: {messages: '参数错误'}, status: 400
    end
  end

  def attachments_show
    @attachments = Performance.find(params[:id]).attachments
    render template: '/api/performance_attachments/show'
  end

  def attachments_destroy
    @attachment = PerformanceAttachment.find(params[:id])

    if @attachment.present? && @attachment.employee_id != @current_employee.id
      render json: {messages: '只有上传该附件的人能删除'}, status: 400 and return
    end

    if @attachment.destroy
      render json: {messages: '附件删除成功'}
    else
      render json: {messages: '参数错误'}, status: 400
    end
  end

  def import_performance_collect
    attachment = Attachment.find_by(id:params[:attachment_id])
    if attachment.nil?
      return render json: {messages: "文件上传错误，请重新上传"}, status: 400
    end
    importor = Excel::PerformanceCollectImportor.new(attachment.full_path)
    importor.valid_format
    if importor.errors.present?
      return render json: {messages: importor.errors}, status: 400
    else
      importor.import
      if importor.errors.present?
        return render json: {messages: importor.errors}, status: 400
      else
        render json: {messages: "导入成功"}
      end
    end
  end

  private
  def temp_params
    safe_params([:month_distribute_base, :pcategory])
  end

  def get_employees
    @employees = Employee.includes(
      [
        :department,\
        :positions => [:department],
      ]
    ).joins(
      "JOIN departments ON departments.id = employees.department_id"
    ).order(
      "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no"
    )

    if !(@current_employee.hr? and !@current_employee.department_hr?) and !@current_employee.company_leader?
      department_ids = @current_employee.get_departments_for_role

      if department_ids.present?
        @employees = @employees.joins(:positions)
          .where("positions.department_id in (?) or employees.id = #{@current_employee.id}", department_ids)
      else
        @employees = @employees.joins(:positions).where("employees.id = #{@current_employee.id}")
      end
    end
  end
end

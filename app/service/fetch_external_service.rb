class FetchExternalService
  def initialize(params)
    @params = params
    @data = nil
  end

  def fetch_update_phone
    @employee_no = @params[:employeeNo]
    return nil, {code: '-10009', message: '员工编号不存在'} unless @employee_no.present?

    @employee = Employee.unscoped.find_by(employee_no: @employee_no)
    return nil, {code: '-10009', message: '员工不存在'} unless @employee.present?

    @contact = @employee.contact
    return nil, {code: '-10009', message: '员工联系方式不存在'} unless @contact.present?

    @contact.update({telephone: @params[:telephone], mobile: @params[:mobile]})
    return nil, {code: '0', message: '已更新'}
  end

  def fetch_department
    org_numbers = @params.fetch(:orgNumber, '').split(',')

    @data = Department.includes(:grade, :nature).order(:d1_sort_no, :d2_sort_no, :d3_sort_no)
    if org_numbers.present?
      @data = @data.where(serial_number: org_numbers)
    end

    self
  end

  def fetch_employee
    org_numbers = @params.fetch(:orgNumber, '').split(',')

    @data = Employee.unscoped.includes(
      [:job_title_degree, :gender, :degree, :political_status,\
       :education_background, :master_positions, :languages,\
       :category, :labor_relation, :channel, \
       :employee_positions, :department, :duty_rank]
    ).joins(:department).order(
      "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no"
    )
    if org_numbers.present?
      @data = @data.where("departments.serial_number in (?)", org_numbers)
    end

    if @params[:employeeNo].present?
      @data = @data.where("employees.employee_no = ?", @params[:employeeNo])
    end

    self
  end
  def fetch_performance
    start_time, end_time = @params[:startTime], @params[:endTime]
    year = @params[:year]
    category = @params[:category]
    employeeNos = @params.fetch(:employeeNo,'').split(',')
    query_sql = []
    query_sql_arr = []
    if year.present?
      query_sql << ' assess_year = ? '
      query_sql_arr << year
    end
    if start_time.present?
      query_sql << ' assess_time >= ? '
      query_sql_arr << Time.at(start_time.to_i).to_datetime
    end

    if end_time.present?
      query_sql << ' assess_time <= ? '
      query_sql_arr << Time.at(end_time.to_i).to_datetime
    end
    if employeeNos.present?
      query_sql << ' employee_no in (?)'
      query_sql_arr << employeeNos
    end

    if category.present?
      query_sql << ' category = ? '
      query_sql_arr << category
    end
    if query_sql_arr.empty?
      @data = Performance.all
    else
      query_sql_arr.insert(0,query_sql.join("AND"))
      @data = Performance.where(query_sql_arr)
    end
    @data = @data.order('assess_time')
    self
  end

  def fetch_change_record
    change_type = @params[:changeType]
    start_time, end_time = @params[:startTime], @params[:endTime]
    query_sql = []

    query_sql << "change_type = '#{change_type}'" if change_type
    query_sql << "event_time >= '#{Time.at(start_time.to_i).to_datetime}'" if start_time
    query_sql << "event_time <= '#{Time.at(end_time.to_i).to_datetime}'" if end_time

    if query_sql.empty?
      @data = ChangeRecord.all
    else
      @data = ChangeRecord.where(query_sql.join(" AND "))
    end

    self
  end


  def paginate_external(type)
    page={}
    page[:per_page] = @params.fetch(:count, 60)
    page[:page] = @params.fetch(:lastId, 1)

    return @data if @params[:fetchAll].to_i == 1
    @data.paginate(page)
  end
end
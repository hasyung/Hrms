class Api::SpecialStatesController < ApplicationController
  def index
    result = parse_query_params!('employee')
    render json: {messages: result[:error]}, status: 400 and return unless result[:error].blank?
    relations, conditions, sorts, page = result.values

    # @employees = Employee.all
    @special_states = SpecialState.joins(relations)
    .joins("JOIN employees ON employees.id = special_states.employee_id")
    .joins("JOIN departments ON departments.id = employees.department_id")
    .order("departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no")

    if !(@current_employee.hr? and !@current_employee.department_hr?) and !@current_employee.company_leader?
      department_ids = @current_employee.get_departments_for_role

      if department_ids.present?
        # @employees = @employees.joins("")
        #   .where("positions.department_id in (?) or employees.id = #{@current_employee.id}", department_ids)
        @special_states = @special_states
        .joins("JOIN employees ON employees.id = special_states.employee_id")
        .joins("JOIN departments ON departments.id = employees.department_id")
        .where("departments.id in (?) or special_states.id = #{@current_employee.id}", department_ids)
      else
        @special_states = @employees.where("employees.id = #{@current_employee.id}")
      end
    end

    # @employees = @employees.joins(relations).order(sorts)

    # @special_states = SpecialState
    # .includes(
    #   [
    #     :employee => [:department, :positions]
    #   ]
    # ).joins(
    #   employee: :department
    # ).joins(
    #   employee: :positions
    # ).where(
    #   employee_id: @employees.map(&:id)
    # ).order(
    #   created_at: "DESC"
    # ).uniq

    conditions.each do |condition|
     @special_states = @special_states.where(condition)
    end

    @special_states = @special_states.where(special_category: params[:special_category]) if params[:special_category].present?
    @special_states = @special_states.where("special_location like '%#{params[:special_location]}%'") if params[:special_location].present?
    
    @special_states = set_page_meta @special_states.uniq, page
  end

  def show
    @special_state = SpecialState.find params[:id]
    render template: "/api/special_states/show"
  end

  def update
    #异动变更(时间, 文件号)
    @special_state = SpecialState.where(id: params[:id]).first

    if @special_state.present? && @special_state.update(limit_update_date)
      render json: {messages: "修改成功"}
    else
      render json: {messages: '修改失败'}, status: 400
    end
  end

  def temporarily_transfer
    #借调
    employee          = Employee.where(id: params[:employee_id]).first
    sponsor_id        = current_employee.id
    department        = Department.where(id: params[:department_id]).first
    out_company       = params[:out_company]
    special_date_from = params[:special_date_from]
    special_date_to   = params[:special_date_to]
    file_no           = params[:file_no]

    if special_date_from.blank?
      render json: {messages: "开始时间不能为空"}, status: 400 and return
    elsif employee.blank?
      render json: {messages: "员工不能为空"}, status: 400 and return
    elsif out_company == false && department.blank?
      render json: {messages: "公司内借调,请选择部门"}, status: 400 and return
    end

    if out_company
      special_location = params[:special_location] || "公司外"
    else
      special_location = department.full_name
    end

    
    
    records = employee.special_states.where("special_date_to >= ? or special_date_to is null and special_category = ?", special_date_from, '借调')
    if records.map(&:special_date_to).include?(nil)
      render json: {messages: "员工处于异动期间，不能重复异动"}, status: 400 and return
    else
      # 将异动的所有日期加入到一个数组
      transfer_dates = records.inject([]) do |transfer_dates, record|
        transfer_dates << Range.new(record.special_date_from, record.special_date_to).to_a
        transfer_dates
      end.flatten
      # 判断派驻时间是否在借调时间之内
      Range.new(special_date_from.to_date, (special_date_to || Time.now).to_date).to_a.each do |date|
        if transfer_dates.size > 0
          if transfer_dates.include?(date)
            render json: {messages: "员工处于异动期间，不能重复异动"}, status: 400 and return
          end
        end
      end
    end

    @special_state = SpecialState.new(
      employee_id:       employee.id,
      sponsor_id:           sponsor_id,
      department_id:     department.present? ? department.id : "",
      out_company:       out_company,
      special_category:  "借调",
      special_location:  special_location,
      special_date_from: special_date_from,
      special_date_to:   special_date_to,
      file_no:           file_no
    )


    if @special_state.save!
      render template: '/api/special_states/show'
    else
      render json: {messages: '参数错误'}, status: 400
    end
  end

  def temporarily_defend
    #派驻
    employee          = Employee.where(id: params[:employee_id]).first
    sponsor_id        = current_employee.id
    special_location  = params[:special_location]
    out_company       = params[:out_company]
    special_date_from = params[:special_date_from]
    special_date_to   = params[:special_date_to]
    file_no           = params[:file_no]

    
    if special_date_from.blank?
      render json: {messages: "开始时间不能为空"}, status: 400 and return
    elsif employee.blank?
      render json: {messages: "员工不能为空"}, status: 400 and return
    elsif out_company == false && special_location.blank?
      render json: {messages: "公司内部驻派,请输入地点"}, status: 400 and return
    elsif judge_repeat_date(employee, special_date_from, special_date_to)
      render json: {messages: "员工异动期限重叠"}, status: 400 and return
    end

    department_name = employee.department.parent_chain.first.name
    if department_name != "机务工程部" && department_name != "航空医疗卫生中心" && department_name != "计划财务部"
      records = employee.special_states.where(special_category: '借调')
      # 将借调的所有日期加入到一个数组
      transfer_dates = records.inject([]) do |transfer_dates, record|
        transfer_dates << Range.new(record.special_date_from, record.special_date_to).to_a
        transfer_dates
      end.flatten
      # 判断派驻时间是否在借调时间之内
      Range.new(special_date_from.to_date, special_date_to.to_date).to_a.each do |date|
        if transfer_dates.size > 0
          unless transfer_dates.include?(date)
            render json: {messages: "员工处于借调期间，派驻时间必须介于借调时间段之内"}, status: 400 and return
          end
        end
      end
    end

    records = employee.special_states.where("special_date_to >= ? or special_date_to is null and special_category = ?", special_date_from, "派驻")
    if records.map(&:special_date_to).include?(nil)
      render json: {messages: "员工处于异动期间，不能重复异动"}, status: 400 and return
    else
      # 将异动的所有日期加入到一个数组
      transfer_dates = records.inject([]) do |transfer_dates, record|
        transfer_dates << Range.new(record.special_date_from, record.special_date_to).to_a
        transfer_dates
      end.flatten
      # 判断派驻时间是否在借调时间之内
      Range.new(special_date_from.to_date, (special_date_to || Time.now).to_date).to_a.each do |date|
        if transfer_dates.size > 0
          if transfer_dates.include?(date)
            render json: {messages: "员工处于异动期间，不能重复异动"}, status: 400 and return
          end
        end
      end
    end

    @special_state  = SpecialState.new(
      employee_id:       employee.id,
      sponsor_id:           sponsor_id,
      special_location:  out_company ? "公司外" : special_location,
      out_company:       out_company,
      special_category:  "派驻",
      special_date_from: special_date_from,
      special_date_to:   special_date_to,
      file_no:           file_no
    )

    if @special_state.save!
      render template: "/api/special_states/show"
    else
      render json: {messages: '参数错误'}, status: 400
    end
  end

  def temporarily_train
    #离岗培训
    employee          = Employee.where(id: params[:employee_id]).first
    sponsor_id        = current_employee.id
    special_date_from = params[:special_date_from]
    special_date_to   = params[:special_date_to]
    file_no           = params[:file_no]

    if special_date_from.blank?
      render json: {messages: "开始时间不能为空"}, status: 400 and return
    elsif employee.blank?
      render json: {messages: "员工不能为空"}, status: 400 and return
    end

    @special_state = SpecialState.new(
      employee_id:       employee.id,
      sponsor_id:           sponsor_id,
      special_category:  '离岗培训',
      special_date_from: special_date_from,
      special_date_to:   special_date_to,
      file_no:           file_no
    )

    records = employee.special_states.where("special_date_to >= ? or special_date_to is null and special_category = ?", special_date_from, '离岗培训')
    if records.map(&:special_date_to).include?(nil)
      render json: {messages: "员工处于异动期间，不能重复异动"}, status: 400 and return
    else
      # 将异动的所有日期加入到一个数组
      transfer_dates = records.inject([]) do |transfer_dates, record|
        transfer_dates << Range.new(record.special_date_from, record.special_date_to).to_a
        transfer_dates
      end.flatten
      # 判断派驻时间是否在借调时间之内
      Range.new(special_date_from.to_date, (special_date_to || Time.now).to_date).to_a.each do |date|
        if transfer_dates.size > 0
          if transfer_dates.include?(date)
            render json: {messages: "员工处于异动期间，不能重复异动"}, status: 400 and return
          end
        end
      end
    end

    if @special_state.save!
      # @special_state.summary_cultivate
      render template: "/api/special_states/show"
    else
      render json: {messages: '参数错误'}, status: 400
    end
  end

  def temporarily_stop_air_duty
    #空勤停飞
    employee          = Employee.where(id: params[:employee_id]).first
    sponsor_id        = current_employee.id
    special_date_from = params[:special_date_from]
    special_date_to   = params[:special_date_to]
    file_no           = params[:file_no]
    special_category  = params[:special_category]
    stop_fly_reason   = params[:stop_fly_reason]

    if special_date_from.blank?
      render json: {messages: "开始时间不能为空"}, status: 400 and return
    elsif special_category.blank?
      render json: {messages: "停飞种类不能为空"}, status: 400 and return
    elsif employee.blank?
      render json: {messages: "员工不能为空"}, status: 400 and return
    end

    @special_state = SpecialState.new(
      employee_id:       employee.id,
      sponsor_id:           sponsor_id,
      special_category:  special_category,
      special_date_from: special_date_from,
      special_date_to:   special_date_to,
      stop_fly_reason:   stop_fly_reason,
      file_no:           file_no
    )

    records = employee.special_states.where("special_date_to >= ? or special_date_to is null and special_category = ?", special_date_from, '空勤停飞')
    if records.map(&:special_date_to).include?(nil)
      render json: {messages: "员工处于异动期间，不能重复异动"}, status: 400 and return
    else
      # 将异动的所有日期加入到一个数组
      transfer_dates = records.inject([]) do |transfer_dates, record|
        transfer_dates << Range.new(record.special_date_from, record.special_date_to).to_a
        transfer_dates
      end.flatten
      # 判断派驻时间是否在借调时间之内
      Range.new(special_date_from.to_date, (special_date_to || Time.now).to_date).to_a.each do |date|
        if transfer_dates.size > 0
          if transfer_dates.include?(date)
            render json: {messages: "员工处于异动期间，不能重复异动"}, status: 400 and return
          end
        end
      end
    end

    if @special_state.save!
      render template: "/api/special_states/show"
    else
      render json: {messages: '参数错误'}, status: 400
    end
  end

  def temporarily_business_trip
    #出差
    employee          = Employee.where(id: params[:employee_id]).first
    sponsor_id        = current_employee.id
    department        = Department.where(id: params[:department_id]).first
    out_company       = params[:out_company]
    special_date_from = params[:special_date_from]
    special_date_to   = params[:special_date_to]
    file_no           = params[:file_no] ? params[:file_no] : nil

    if special_date_from.blank?
      render json: {messages: "开始时间不能为空"}, status: 400 and return
    elsif employee.blank?
      render json: {messages: "员工不能为空"}, status: 400 and return
    elsif out_company == false && department.blank?
      render json: {messages: "公司内出差,请选择部门"}, status: 400 and return
    end

    if out_company
      special_location = params[:special_location] || "公司外"
    else
      special_location = department.full_name
    end

    records = employee.special_states.where("special_date_to >= ? or special_date_to is null and special_category = ?", special_date_from, '出差')
    if records.map(&:special_date_to).include?(nil)
      render json: {messages: "员工处于异动期间，不能重复异动"}, status: 400 and return
    else
      # 将异动的所有日期加入到一个数组
      transfer_dates = records.inject([]) do |transfer_dates, record|
        transfer_dates << Range.new(record.special_date_from, record.special_date_to).to_a
        transfer_dates
      end.flatten
      # 判断派驻时间是否在借调时间之内
      Range.new(special_date_from.to_date, (special_date_to || Time.now).to_date).to_a.each do |date|
        if transfer_dates.size > 0
          if transfer_dates.include?(date)
            render json: {messages: "员工处于异动期间，不能重复异动"}, status: 400 and return
          end
        end
      end
    end

    @special_state = SpecialState.new(
      employee_id:       employee.id,
      sponsor_id:           sponsor_id,
      department_id:     department.present? ? department.id : "",
      out_company:       out_company,
      special_category:  "出差",
      special_location:  special_location,
      special_date_from: special_date_from,
      special_date_to:   special_date_to,
      file_no:           file_no
    )


    if @special_state.save!
      render template: '/api/special_states/show'
    else
      render json: {messages: '参数错误'}, status: 400
    end
  end

  def export_xls
    special_state_writer = Excel::SpecialStateWriter.new(SpecialState.all).write_excel
    hash = {
      path:special_state_writer[:path],
      file_name:special_state_writer[:filename]
    }
    send_file(special_state_writer[:path], filename: special_state_writer[:filename])
    # render json:hash
  end

  private
  def limit_update_date
    params.permit(:special_date_to, :file_no)
  end

  def judge_repeat_date(employee, start_time, end_time)
    if end_time.present?
      duration = Range.new(start_time.to_date, end_time.to_date).to_a
    else
      duration = Range.new(start_time.to_date, Date.today + 40.year).to_a
    end
    employee.special_states.where(special_category: "派驻").order(:special_date_to).each do |item|
      if item.special_date_to.blank?
        old_duration = Range.new(item.special_date_from, Date.today + 40.year).to_a
      else
        old_duration = Range.new(item.special_date_from, item.special_date_to).to_a
      end

      return true if (duration & old_duration).count > 0
    end
    false
  end
end

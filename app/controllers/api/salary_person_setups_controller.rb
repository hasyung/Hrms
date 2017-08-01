class Api::SalaryPersonSetupsController < ApplicationController
  include ExceptionHandler

  def index
    result = parse_query_params!('salary_person_setup')
    render json: {messages: result[:error]}, status: 400 and return unless result[:error].blank?
    relations, conditions, sorts, page = result.values

    @salary_person_setups = SalaryPersonSetup.includes(employee: [:department, :master_positions]).joins(employee: :department).joins(relations).order(
      "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no"
    ).order(sorts)

    conditions.each do |condition|
      @salary_person_setups = @salary_person_setups.where(condition)
    end
    @salary_person_setups = set_page_meta @salary_person_setups, page
  end

  def import_hours_fee_setup
    attachment = Attachment.find_by(id: params[:attachment_id])

    if %w(xls xlsx).exclude?(attachment.file_type.downcase)
      return render json: {messages: "对不起，目前仅支持xls和xlsx文件导入"}, status: 400
    end

    if attachment.blank?
      return render json: {messages: "参数错误"}, status: 400
    else
      message = Excel::Salary::FlyerImportor.import(attachment.file.url, true)
      render json: message
    end
  end

  def export_to_xls
    result = parse_query_params!('salary_person_setup')
    render json: {messages: result[:error]}, status: 400 and return unless result[:error].blank?
    relations, conditions, sorts, page = result.values

    @salary_person_setups = SalaryPersonSetup.includes(employee: [:department, :master_positions, :set_book_info]).joins(employee: :department).joins(relations).order(
      "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no"
    ).order(sorts)

    conditions.each do |condition|
      @salary_person_setups = @salary_person_setups.where(condition)
    end

    excel = Excel::Salary::SalaryPersonSetupExportor.export(@salary_person_setups)
    send_file(excel[:path], filename: excel[:filename])
  end

  # 查看基础工资设置
  def look_basic
    render text: ''
  end

  # 修改基础工资设置
  def update_basic
    render text: ''
  end

  # 查看考核性设置
  def look_performance
    render text: ''
  end

  # 修改考核性设置
  def update_performance
    render text: ''
  end

  # 查看津贴设置
  def look_allowance
    render text: ''
  end

  # 修改津贴设置
  def update_allowance
    render text: ''
  end

  # 查看通讯补贴
  def look_communicate
    render text: ''
  end

  # 修改通讯补贴
  def update_communicate
    render text: ''
  end

  # 查看公务车报销额度
  def look_service_car
    render text: ''
  end

  # 修改公务车报销额度
  def update_service_car
    render text: ''
  end

  # 查看小时费
  def look_hours_fee
    render text: ''
  end

  # 更新小时费
  def update_hours_fee
    render text: ''
  end

  def look_temp
    render text: ''
  end

  def update_temp
    render text: ''
  end

  def update
    @salary_person_setup = SalaryPersonSetup.includes(:employee).find(params[:id])
    #修改员工工资档级记录调档时间
    if ((@salary_person_setup.base_wage != params[:base_wage]) || (@salary_person_setup.base_channel != params[:base_channel]) || (@salary_person_setup.base_flag != params[:base_flag]))
      @record = @salary_person_setup.employee.record_transfer_date(Date.today)
    end

    @salary_person_setup.assign_attributes(salary_params)
    positions = @salary_person_setup.employee.positions
    temp_allowance = positions.map(&:temperature_amount).max
    communicate_allowance = [positions.map(&:communicate_allowance).max, @salary_person_setup.employee.duty_rank.try(:communicate_allowance).to_f].max

    if params[:temp_allowance] != @salary_person_setup.temp_allowance
      @salary_person_setup.temp_allowance = params[:temp_allowance]
    end

    if communicate_allowance && params[:communicate_allowance] != communicate_allowance
      @salary_person_setup.communicate_allowance = params[:communicate_allowance]
    end

    if @salary_person_setup.save
      render template: '/api/salary_person_setups/show'
    else
      @record.destroy if @record.present?
      render json: {messages: '修改失败'}, status: 400
    end
  end

  def create
    employee = Employee.find(params[:employee_id])
    return render json: {messages: '个人薪酬设置已存在'}, status: 400 if employee.salary_person_setup

    if employee.create_salary_person_setup(salary_params)
      employee.record_transfer_date(params[:record_date])
      render json: {message: '成功设置员工薪酬设置'}
    else
      render json: {messages: '新增失败'}, status: 400
    end
  end

  def destroy
    @salary_person_setup = SalaryPersonSetup.find(params[:id])
    if @salary_person_setup.destroy
      render json: {messages: '删除成功'}
    else
      render json: {messages: '删除失败'}, status: 400
    end
  end

  def show
    @salary_person_setup = SalaryPersonSetup.unscoped.find_by(id: params[:id]) || SalaryPersonSetup.unscoped{ Employee.unscoped.find_by(id: params[:employee_id]).try(:salary_person_setup) }
    @second_department = Department.includes(:positions).find_by(id: @salary_person_setup.try(:second_department_id))
  end

  def upload_salary_set_book
    attachment = Attachment.find_by(id: params[:attachment_id])

    if %w(xls xlsx).exclude?(attachment.file_type.downcase)
      return render json: {messages: "对不起，目前仅支持xls和xlsx文件导入"}, status: 400
    end

    if attachment.blank?
      return render json: {messages: "参数错误"}, status: 400
    else
      Excel::SalarySetBookImporter.import(attachment.file.url)
      render json: {messages: "导入完成"}
    end
  end

  def upload_share_fund
    attachment = Attachment.find_by(id: params[:attachment_id])

    if %w(xls xlsx).exclude?(attachment.file_type.downcase)
      return render json: {messages: "对不起，目前仅支持xls和xlsx文件导入"}, status: 400
    end

    if attachment.blank?
      return render json: {messages: "参数错误"}, status: 400
    else
      Excel::ShareFundImporter.import(attachment.file.url)
      render json: {messages: "导入完成"}
    end
  end

  def check_person_upgrade
    if params[:type] == 'position'
      SalaryPersonSetup.check_working_years_salary
      PositionUpgradeWorker.perform_async(@current_employee.id)
      render json: {messages: "任务已经加入后台队列，处理中"}
    elsif params[:type] == 'performance'
      render json: {messages: "请检查员工年度绩效是否已经全部导入" }, status: 400 and return if SalaryPersonSetup.check_performance_upgrade_condition
      PerformanceUpgradeWorker.perform_async(@current_employee.id)
      render json: {messages: "任务已经加入后台队列，处理中"}
    else
      return render json: {messages: "调整类型是必须的参数"}, status: 400
    end
  end

  private
  def salary_params
    params.permit(
      :base_wage, :base_channel, :base_flag, :base_money, :reserve_wage,
      :performance_wage, :performance_flag, :performance_channel,
      :performance_money, :security_subsidy, :leader_subsidy, :terminal_subsidy,
      :ground_subsidy, :machine_subsidy, :trial_subsidy, :honor_subsidy,
      :placement_subsidy, :car_subsidy, :fly_hour_fee, :fly_hour_money,
      :airline_hour_fee, :airline_hour_money, :security_hour_fee,
      :security_hour_money, :land_type, :limit_leader, :is_salary_special,
      :working_years_salary, :double_department_check,
      :second_department_id, :official_car, :lowest_fly_time,
      :lowest_calc_time, :leader_subsidy_time, :fly_check_lifecycle,
      :base_performance_money, :keep_position, :keep_performance,
      :keep_working_years, :keep_minimum_growth, :keep_land_allowance,
      :keep_life_1, :keep_life_2, :keep_adjustment_09, :keep_bus_14,
      :keep_communication_14, :airline_attendant_type, :join_salary_scal_date,
      :leader_grade, :lower_limit_hour, :leader_subsidy_hour, :technical_grade,
      :is_flyer_land_work, :flyer_science_subsidy, :flyer_science_money, 
      :performance_position, :technical_category, :building_subsidy, 
      :on_duty_subsidy, :retiree_clean_fee, :maintain_subsidy, 
      :part_permit_entry, :cq_part_time_fix_car_subsidy, :watch_subsidy, 
      :logistical_support_subsidy, :flyer_student_train, :is_send_flyer_science,
      :is_send_airline_fee, :is_send_transport_fee
    )
  end
end

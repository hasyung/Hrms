class Api::PerformanceSalariesController < ApplicationController 
  skip_before_action :authenticate_user!, only: [:new, :create]
  skip_before_action :check_action_register
  skip_before_action :check_permission
  before_action :check_month, only: [:compute, :export_base_salary]

  def index
    result = parse_query_params!('performance_salary')
    render json: {messages: result[:error]}, status: 400 and return unless result[:error].blank?
    relations, conditions, sorts, page = result.values

    @performance_salaries = PerformanceSalary.joins(employee: :department).joins(relations).order(
      "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no"
    ).order(sorts)

    conditions.each do |condition|
      @performance_salaries = @performance_salaries.where(condition)
    end

    @performance_salaries = set_page_meta @performance_salaries, page
  end

  def compute
    message = SalaryPersonSetup.check_compute(params[:month])
    return render json: {basic_salaries: [], messages: message} if message
    
    if params[:type] == "base_salary"
      is_success, messages = PerformanceSalary.cal_base_salary(params[:month])
      return render json: {performance_salaries: [], messages: messages || "计算发生错误"}, status: 400 if !is_success
    else
      PerformanceSalary.cal_salary(params[:month])
    end

    @performance_salaries = PerformanceSalary.joins(employee: :department).order(
      "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no"
    ).where("performance_salaries.month = '#{params[:month]}'")
    page = parse_query_params!("performance_salary").values.last
    @performance_salaries = set_page_meta(@performance_salaries, page)

    render template: 'api/performance_salaries/index'
  end

  def import
    render json: {messages: "月份不能为空"}, status: 400 and return unless params[:assess_time]

    file = Attachment.find(params[:file_id]).full_path
    @performance_importer = Excel::MonthPerformanceImporter.new(file, params[:assess_time], params[:category], params[:department_id]).parse

    if @performance_importer.valid?
      @performance_importer.call 
      
      render json: {messages: "导入成功", warnings: @performance_importer.warning_message}
    else
      render json: {messages: @performance_importer.errors}, status: 400
    end
  end

  def export_base_salary
    department_id = @current_employee.department.parent_chain.first.id
    salaries = get_base_salaries(department_id)

    if salaries.blank?
      Notification.send_system_message(current_employee.id, {error_messages: '导出数据为空'})
      return render text: ''
    end
    excel = Excel::PerformanceSalaryExportor.export_base_salary(salaries, params[:month], department_id)
    send_file(excel[:path], filename: excel[:filename])
  end

  def export_point_base_salary
    salaries = get_base_salaries(params[:department_id])

    if salaries.blank?
      Notification.send_system_message(current_employee.id, {error_messages: '导出数据为空'})
      return render text: ''
    end
    excel = Excel::PerformanceSalaryExportor.export_base_salary(salaries, params[:month], params[:department_id])
    send_file(excel[:path], filename: excel[:filename])
  end

  def export_nc
    if(params[:month])
      salaries = PerformanceSalary.joins(employee: [:department, :channel]).order(
        "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no"
        ).where("performance_salaries.month = '#{params[:month]}' and code_table_channels.display_name 
        != '飞行' and code_table_channels.display_name != '空勤'")
      if salaries.blank?
        Notification.send_system_message(current_employee.id, {error_messages: '导出数据为空'})
        return render text: ''
      end
      excel = Excel::PerformanceSalaryExportor.export_nc(salaries, params[:month])
      send_file(excel[:path], filename: excel[:filename])
    else
      Notification.send_system_message(current_employee.id, {error_messages: '条件不足'})
      return render text: ''
    end
  end

  def export_approval
    if(params[:month])
      excel = Excel::PerformanceSalaryExportor.export_approval(params[:month])
      send_file(excel[:path], filename: excel[:filename])
    else
      Notification.send_system_message(current_employee.id, {error_messages: '条件不足'})
      return render text: ''
    end
  end

  def update
    @performance_salary = PerformanceSalary.find(params[:id])

    if @performance_salary.update(performance_salary_params)
      render template: '/api/performance_salaries/show'
    else
      render json: {messages: '修改失败'}, status: 400
    end
  end

  private
  def performance_salary_params
    params.permit(:add_garnishee, :remark)
  end

  def check_month
    unless params[:month]
      Notification.send_system_message(current_employee.id, {error_messages: '月份不能为空'})
      return render text: ''
    end
  end

  def get_base_salaries(department_id)
    compute_month = Date.parse(params[:month] + "-01")
    department_ids = Department.get_self_and_childrens([department_id])
    outer_records = Employee.joins("LEFT JOIN `position_change_records` ON `position_change_records`.`employee_id` = `employees`.`id`")
      .joins("LEFT JOIN `special_states` ON `special_states`.`employee_id` = `employees`.`id`")
      .where("(position_change_records.position_change_date <= '#{Date.current.to_s}' 
      and position_change_records.position_change_date < '#{compute_month.next_month.to_s}' 
      and position_change_records.position_change_date > '#{compute_month.to_s}' 
      and employees.department_id in (?) and position_change_records.prev_department_id not in 
      (?)) or (special_states.special_category = '借调' and employees.department_id in (?) and 
      ((special_states.department_id is null or special_states.department_id not in (?)) and 
      (special_states.special_date_from <= '#{Date.parse(params[:month] + "-15")}' and (special_states.special_date_to 
      is null or special_states.special_date_to >= '#{compute_month.end_of_month}')) or 
      (special_states.special_date_from <= '#{compute_month}' and special_states.special_date_to >= 
      '#{Date.parse(params[:month] + "-15")}')))", 
      department_ids, department_ids, department_ids, department_ids)
    inner_records = Employee.joins("LEFT JOIN `position_change_records` ON `position_change_records`.`employee_id` = `employees`.`id`")
      .joins("LEFT JOIN `special_states` ON `special_states`.`employee_id` = `employees`.`id`")
      .where("(position_change_records.position_change_date <= '#{Date.current.to_s}' 
      and position_change_records.position_change_date < '#{compute_month.next_month.to_s}' 
      and position_change_records.position_change_date > '#{compute_month.to_s}' 
      and position_change_records.prev_department_id in (?)) or (special_states.special_category 
      = '借调' and employees.department_id not in (?) and special_states.department_id in (?) and 
      ((special_states.special_date_from <= '#{Date.parse(params[:month] + "-15")}' and (special_states.special_date_to is null 
      or special_states.special_date_to >= '#{compute_month.end_of_month}')) or 
      (special_states.special_date_from <= '#{compute_month}' and special_states.special_date_to >= 
      '#{Date.parse(params[:month] + "-15")}')))",
      department_ids, department_ids, department_ids)

    salaries = PerformanceSalary.joins(employee: [:department, :salary_person_setup]).order(
      "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, employees.sort_no")
      .where("performance_salaries.month = '#{params[:month]}' and employees.pcategory != '主官' 
      and performance_salaries.base_salary is not null and performance_salaries.base_salary > 0")
    if outer_records.present?
      salaries = salaries.where("performance_salaries.employee_id not in (?)", outer_records.map(&:id))
    end
    if inner_records.present?
      salaries = salaries.where("employees.id in (?) or departments.id in (?) or 
        (salary_person_setups.double_department_check = 1 and salary_person_setups.second_department_id 
        in (?))", inner_records.map(&:id), department_ids, department_ids)
    else
      salaries = salaries.where("departments.id in (?) or (salary_person_setups.double_department_check = 1 
        and salary_person_setups.second_department_id in (?))", department_ids, department_ids)
    end
    salaries
  end

end
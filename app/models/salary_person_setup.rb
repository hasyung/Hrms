class SalaryPersonSetup < ActiveRecord::Base
  attr_accessor :import_mode

  belongs_to :employee

  default_scope {where(is_stop: false)}

  validates :employee_id, uniqueness: true

  before_save do
    unless self.import_mode
      # 飞行通道并且是飞行学员
      if self.employee.is_fly_channel? && self.base_wage_was == 'flyer_student_base' && self.base_wage != "flyer_student_base"
        self.employee.update(leave_flyer_student_date: Time.new.to_date)
      end
    end
  end

  # 计算各项薪酬的时候应该跳过去的人员
  def is_special_category
    self.is_salary_special || self.employee.try(:channel).try(:name) == "服务A"
  end

  def upgrade_working_years_salary
    return if self.employee.join_scal_date > Date.today.last_year.beginning_of_year
    SalaryPersonSetup.transaction do
      self.update(working_years_salary: self.working_years_salary + 40) if self.working_years_salary.present?
    end
  end

  def self.check_compute(compute_month)
    # names = Employee.joins("LEFT JOIN `salary_person_setups` ON `employees`.`id` = `salary_person_setups`.`employee_id`")
    #   .where("salary_person_setups.id is null").map(&:name)
    # return "以下员工个人薪酬设置为空 [#{names.join('，')}]" if names.present?
  end

  def join_salary_scal_years
    return nil unless self.join_salary_scal_date
    Date.difference_in_years(Time.new.strftime("%Y-%m-%d"), self.join_salary_scal_date.strftime("%Y-%m-%d"))
  end

  def temp_money
    # 该函数在show.json中使用，不会被批量调用，所以没有性能问题
    return self.temp_allowance if self.temp_allowance.present?
    self.employee.positions.map(&:temperature_amount).max
  end

  def communicate_money
    if self.communicate_allowance.present?
      return self.communicate_allowance 
    else
      [self.employee.positions.map(&:communicate_allowance).max, self.employee.duty_rank.try(:communicate_allowance).to_f].max
    end
  end

  def official_car_money
    self.official_car.present? ? self.official_car : self.employee.duty_rank.try(:official_car_allowance).to_f
  end

  class << self
    def get_job_title_degree_eval_str
      str = ''
      Employee::JobTitleDegree.all.each do |item|
        str = str + item.display_name + "=" + item.level.to_s + ";"
      end
      str = str + "无=0;"
    end

    def get_education_background_str
      str = ''
      CodeTable::EducationBackground.all.each do |item|
        str = str + item.display_name + "=" + item.level.to_s + ";"
      end
      str = str + "无=0;"
    end

    def check_performance_upgrade_condition
      employee_count = Employee.where("join_scal_date < ?", Date.today-2.year).count
      year_performance_count = Performance.where(category: "year").where("employee_category != '主官'").where(assess_year: Date.today.last_year.year).count
      year_performance_count < employee_count ? true : false
    end
  end

  # 检测绩效工资调档
  def self.check_performance_upgrade(current_employee_id)
    @config = SalaryPersonSetup.load_config()
    @perf_channel_hash = {
      "优秀"    => "A",
      "良好"    => "B",
      "合格"    => "C",
      "待改进"  => "D",
      "随动"    => "E"
    }

    Employee.includes(:salary_person_setup, :channel).find_in_batches do |group|
      group.each do |employee|
        @channel = employee.channel
        @setup = employee.salary_person_setup

        next unless @setup # 没有个人薪酬设置
        next unless @setup.performance_wage # 没有设置绩效通道
        #TODO 特殊薪酬绩效人员跳过

        @performance_config = @config[@setup.performance_wage]["form_data"]["flags"]
        @performance_channel = @perf_channel_hash[employee.last_year_perf]
        next if @performance_channel.blank?

        @performance_config.each do |flag, item|
          if item[@performance_channel].present? && item[@performance_channel]["expr"].present?
            if SalaryPersonSetup.eval_expr(item[@performance_channel]["expr"], employee)
              @transfer_flag = flag
            else
              break
            end
          end
        end

        employee.update_salary_grade_change_record("绩效工资", @setup, {
          performance_wage: @setup.performance_wage,
          performance_channel: @perf_channel_hash[employee.last_year_perf],
          performance_flag: @transfer_flag,
        }) if @transfer_flag.present?  && @transfer_flag != @setup.performance_flag
      end
      Notification.send_system_message(current_employee_id, {reload_flag_str: SecureRandom.hex})
    end
  end

  #检测工龄工资调整
  def self.check_working_years_salary
    SalaryPersonSetup.includes([:employee]).joins(employee: :positions).where("positions.channel_id not in (?)", CodeTable::Channel.where("display_name = '服务A' or display_name = '服务B'").pluck(:id)).each do |item|
      item.upgrade_working_years_salary
    end
  end

  # 检测岗位工资调档
  def self.check_position_upgrade(current_employee_id)
    @config = SalaryPersonSetup.load_config()

    Employee.includes(:salary_person_setup, :channel).find_in_batches do |group|
      group.each do |employee|
        puts "计算#{employee.id}: #{employee.name}"
        @channel = employee.channel
        @setup = employee.salary_person_setup

        next unless @setup #没有个人薪酬设置
        next unless @setup.base_wage #没有基础工资设置
        next if SalaryPersonSetup.is_single?(@setup.base_wage)

        @wage_config  = @config[@setup.base_wage]["form_data"]["flags"]
        @wage_channel = @setup.base_channel
        next if @wage_config[@setup.base_flag][@wage_channel]['format_cell'].strip == '封顶'
        next if @wage_config[@setup.base_flag][@wage_channel]['format_cell'].strip == '荣誉级'
        @nature = SalaryPersonSetup.is_nature?(@setup.base_wage)
        @old_current_flag = @setup.base_flag

        while true
          @current_flag = (@old_current_flag.to_i + (@nature ? 1 : -1)).to_s
          next if @wage_config[@current_flag][@wage_channel].blank?
          @current_expr = @wage_config[@current_flag][@wage_channel]["expr"]
          if SalaryPersonSetup.eval_expr(@current_expr, employee)
            @old_current_flag = @current_flag
            break if @wage_config[@current_flag][@wage_channel]["format_cell"].strip == '封顶'
          else
            break
          end
        end

        employee.update_salary_grade_change_record("岗位工资", @setup, {
          base_wage: @setup.base_wage,
          base_channel: @wage_channel,
          base_flag: @old_current_flag,
        }) if @old_current_flag.present? && @old_current_flag != @setup.base_flag
      end
      Notification.send_system_message(current_employee_id, {reload_flag_str: SecureRandom.hex})
    end
  end

  def self.load_config
    Salary.all.index_by(&:category)
  end

  # 档级是否是自然升序
  def self.is_nature?(category)
    !["flyer_leader_base", "flyer_copilot_base", "flyer_teacher_A_base", "flyer_teacher_B_base", "flyer_teacher_C_base"].include?(category)
  end

  # 是否只有1个档级
  def self.is_single?(category)
    ["flyer_student_base", "flyer_legend_base"].include?(category)
  end

  # 替换变量，解析表达式结果
  def self.eval_expr(expr, employee)
    return true if expr.blank?  # 没有表达式视为通过

    # 调档时间 %{transfer_years}
    # 驾驶经历年限 %{drive_work_years}
    # 教员经历年限 %{teacher_drive_years}
    # 飞行时间 %{fly_time_value}
    # 员工学历 %{education_background}
    # 员工职级 %{job_title_degree}
    # 去年年度绩效 %{last_year_perf}
    # 本企业经历年限 %{join_scal_years}
    # 无人为飞行事故年限 %{no_subjective_accident_years}
    # 无安全严重差错年限 %{no_serious_security_error_years}
    # 高原特殊机场飞行资格 %{can_fly_highland_special}

    hash = {
      transfer_years: employee.last_transfer_date != nil ? (Date.today.last_year.end_of_year - employee.last_transfer_date)/365 : 0,
      drive_work_years: employee.drive_date != nil ? (Date.today.last_month.end_of_month -  employee.drive_date)/365 : 0 ,
      teacher_drive_years: employee.teacher_date != nil ? (Date.today.last_month.end_of_month - employee.teacher_date)/365 : 0 ,
      fly_time_value: employee.fly_total_time != nil ? employee.fly_total_time : 0,
      job_title_degree: employee.job_title_degree.try(:display_name) ? employee.job_title_degree.try(:display_name): "无",
      education_background: employee.education_background.try(:display_name) ? employee.education_background.try(:display_name) : "无",
      last_year_perf: employee.last_year_perf,
      join_scal_years: employee.salary_person_setup.join_salary_scal_date.present? ? (Date.today.last_year.end_of_year - employee.salary_person_setup.join_salary_scal_date)/365 : (Date.today.last_year.end_of_year - employee.join_scal_date)/365,
      no_subjective_accident_years: 10, # 可直接过
      no_serious_security_error_years: 10, # 可直接过
      can_fly_highland_special: true, # 可直接过
    }

    # 可能因为表达式开发编辑原因的，这里可能会出现异常或者未知变量
    @result = false

    str = "优秀='优秀';良好='良好';合格='合格';待改进='待改进';随动='随动';"

    str = str + SalaryPersonSetup.get_job_title_degree_eval_str + SalaryPersonSetup.get_education_background_str

    expr = str + expr

    begin
      @result = class_eval(expr % hash)
    rescue => ex
      puts ex
    end

    @result
  end
end

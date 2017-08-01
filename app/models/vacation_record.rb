class VacationRecord < ActiveRecord::Base
  belongs_to :employee

  def self.working_dates(start_date, end_date, vacation_type)
    free_dates = check_free_days(start_date, end_date)
    original_dates = Range.new(start_date, end_date).to_a
    working_dates = []

    case vacation_type
    when "年假", "派驻人员休假"
      working_dates = original_dates - free_dates
    when "女工假", "事假", "病假", "病假(工伤待定)", "病假(怀孕待产)", "公假", "婚假", "丧假", "探亲假", "生育护理假", "产前孕期检查假", "产假(流产)", "产假(晚育)", "产假(剖腹产、难产)", "产假(多胞胎)", "产假(母乳喂养)", "哺乳假", "产假", "病假(工伤待定)-工伤假"
      working_dates = original_dates
    end

    working_dates
  end

  def self.cals_days(condition)
    employee = Employee.find_by(id: condition[:employee_id])
    start_date = condition[:start_date]
    end_date = condition[:end_date]

    start_date_str = start_date.strftime("%Y-%m-%d")
    end_date_str = condition[:end_date].strftime("%Y-%m-%d")

    start_time = condition[:start_time]
    end_time = condition[:end_time]
    original_total_days = (end_date - start_date).to_i + 1
    free_days = check_free_days(start_date, end_date, (condition[:vacation_type] != ("年假")) && (condition[:vacation_type] != ("补休假")))

    working_days = 0
    vacation_days = 0

    case condition[:vacation_type]
    when "年假", "补休假"
      # 不包含休息日在内
      if condition[:is_contain_free_day]
        working_days = original_total_days
      else
        working_days = original_total_days - free_days.size
      end

      vacation_days = original_total_days
    when "事假", "病假", "病假(工伤待定)", "病假(怀孕待产)", "公假", "婚假", "丧假", "探亲假", "生育护理假", "产前孕期检查假", "产假(流产)", "产假(晚育)", "产假(剖腹产、难产)", "产假(多胞胎)", "产假(母乳喂养)", "哺乳假", "产假", "病假(工伤待定)-工伤假", "疗养假", "派驻人员休假"
      # 包含休息日在内
      working_days = original_total_days
      vacation_days = working_days
    when "女工假"
      unless free_days.include?(start_date)
        working_days = 1
        vacation_days = 1
      end
    end

    # 处理半天的情况
    # 
    if start_time >= Time.parse("#{start_date_str}T#{Setting.daily_working_hours.afternoon}.000+08:00")
      working_days = working_days - 0.5 if working_days > 0 unless free_days.include?(start_date)
      vacation_days = vacation_days - 0.5 if vacation_days > 0
    end
    if end_time > Time.parse("#{end_date_str}T#{Setting.daily_working_hours.morning}.000+08:00") && end_time <= Time.parse("#{end_date_str}T#{Setting.daily_working_hours.afternoon}.000+08:00")
      working_days = working_days - 0.5 if working_days > 0 unless free_days.include?(end_date)
      vacation_days = vacation_days - 0.5 if vacation_days > 0
    end

    case condition[:vacation_type]
    when "年假","补休假"
      general_days = working_days
    else
      general_days = vacation_days
    end

    
    if condition[:vacation_type] == "年假"
      case condition[:work_shifts]
      when "两班倒"
        general_days = original_total_days
      when "三班倒"
        if VacationRecord.find_by(employee_id:employee.id, record_type:"年假", year:Time.now.year).init_days < 15
          general_days =   format("%.2f",original_total_days.to_f/6*5).to_f 
        else
          general_days = original_total_days
        end
      when "四班倒"
        if original_total_days < 4
          general_days = original_total_days
        else
          general_days = original_total_days/4*3 + original_total_days%4
        end
      end
    end
    
      

    

    hash = {original_total_days: original_total_days,
            free_days: free_days,
            working_days: working_days,
            vacation_days: vacation_days,
            is_air_duty: employee.is_air_duty?,
            total_days: vacation_days + free_days.size,
            general_days: general_days
          }

    if condition[:vacation_type] == "年假"
      hash[:total_year_days] = employee.total_year_days
      hash[:enable] = hash[:total_year_days] >= vacation_days
    end
    hash
  end

  # 这里针对年假等工作日假做计算
  def self.cal_vacation_days(condition)
    start_date = condition[:start_date]
    end_date = condition[:end_date]

    start_date_str = start_date.strftime("%Y-%m-%d")
    end_date_str = condition[:end_date].strftime("%Y-%m-%d")

    start_time = condition[:start_time]
    end_time = condition[:end_time]

    original_total_days = (end_date - start_date).to_i + 1
    free_days = check_free_days(start_date, end_date, false)

    working_days = original_total_days - free_days.size
    vacation_days = original_total_days

    # 处理半天的情况
    
    if start_time >= Time.parse("#{start_date_str}T#{Setting.daily_working_hours.afternoon}.000+08:00")
      working_days = working_days - 0.5 if working_days > 0 unless free_days.include?(start_date)
      vacation_days = vacation_days - 0.5 if vacation_days > 0
    end
    

    
    if end_time > Time.parse("#{end_date_str}T#{Setting.daily_working_hours.morning}.000+08:00") && end_time <= Time.parse("#{end_date_str}T#{Setting.daily_working_hours.afternoon}.000+08:00")
      working_days = working_days - 0.5 if working_days > 0 unless free_days.include?(end_date)
      vacation_days = vacation_days - 0.5 if vacation_days > 0
    end
    

    { working_days: working_days, vacation_days: vacation_days }
  end

  def self.enable_vacation(employee_id)
    @employee = Employee.unscoped.find_by(id: employee_id)
    vacations = ["事假", "病假", "病假(工伤待定)", "婚假", "丧假", "派驻人员休假", "公假", "补休假"]
    vacations <<
     ["产前孕期检查假", "病假(怀孕待产)", "产假(流产)", "产假(晚育)", "产假(剖腹产、难产)", "产假(多胞胎)", "产假(母乳喂养)", "哺乳假", "产假", "女工假"] if @employee.is_female?
    vacations << ["生育护理假"] if @employee.is_male?
    vacations << "年假" if total_days(employee_id) > 0
    vacations << "探亲假" if (@employee.try(:channel).try(:display_name) =~ /服务/).blank?
    vacations.flatten.uniq
  end

  def self.get_last_year_days(employee_id)
    year = Date.today.last_year.year
    @record = VacationRecord.where(employee_id: employee_id, year: year, record_type: "年假").first
    @record.present? ? @record.days : 0
  end

  # 年假剩余情况
  def self.year_days(employee_id)
    @records = VacationRecord.where(employee_id: employee_id, record_type: "年假")
    hash = {year: {}}

    @records.each do |record|
      hash[:year][record.year] = record.days
    end

    hash[:total] = @records.map(&:days).reduce(:+)
    hash[:total] = 0 unless hash[:total]
    hash
  end

  # 总的天数
  def self.total_days(employee_id, record_type="年假")
    @records = VacationRecord.where(employee_id: employee_id, record_type: record_type)
    total = @records.map(&:days).reduce(:+)
    total.nil? ? 0 : total
  end

  # 强制扣减当年的年假
  def self.force_reduce_days(employee_id, record_type="年假")
    year = Time.new.to_date.year
    condition = {employee_id: employee_id, year: year, record_type: record_type}
    @record = VacationRecord.where(condition).first
    return false unless @record

    employee = Employee.find_by(id: employee_id)
    @record.increment!(:days, -1 * get_year_days(employee))
    return true
  end

  # 恢复年假
  def self.restore_reduce_days(employee_id, record_type="年假")
    year = Time.new.to_date.year
    condition = {employee_id: employee_id, year: year, record_type: record_type}
    @record = VacationRecord.where(condition).first
    return false unless @record

    employee = Employee.find_by(id: employee_id)
    working_years = employee.scal_working_years
    @record.increment!(:days, get_year_days(employee))
    return true
  end

  # 扣除补休假
  def self.reduce_offset_days(employee_id, days, record_type = '补休假')
    condition = {
      employee_id: employee_id,
      record_type: record_type
    }
    @record = VacationRecord.where(condition).first

    if @record
      @record.increment!(:days, -1 * days)
      return true
    end
  end

  # 抵扣年假或者请年假，成功返回true，失败返回false
  def self.reduce_days(employee_id, year, days, record_type="年假")
    # 合并天数>0才能抵扣
    return false unless total_days(employee_id) > 0
    
    condition = {employee_id: employee_id, year: (year.to_i - 1).to_s, record_type: record_type}
    @record = VacationRecord.where(condition).first

    if @record
      if @record.days > days
        @record.increment!(:days, -1 * days)
        return true
      else
        days = days - @record.days
        @record.destroy
      end
    end

    @record = VacationRecord.where(employee_id: employee_id, year: year, record_type: record_type).first
    @record.increment!(:days, -1 * days) if @record

    true
  end


  def self.add_days(employee_id, year, days, record_type="年假")
    condition = {employee_id: employee_id, year: year, record_type: record_type}
    @record = VacationRecord.find_or_create_by(condition)
    @record.increment!(:days, days)

    true
  end

  def self.check_fix_update
    last_year = Time.new.last_year.year
    current_year = Time.new.year
    current_date = Time.new.to_date

    return unless current_date.day == 1
    return unless [1, 7].include?(current_date.month)

    #1月1日/7月1日更新年假
    #1月/7月1日扣减上年度的年假，正数扣减成0，负数需要和本年度年假合并
    ActiveRecord::Base.transaction do
      case current_date.month
      when 1
        start_date = Time.parse("#{last_year}-1-1 00:00:00")
        end_date = Time.parse("#{last_year}-6-30 24:00:00")
        update_over_year_days(current_year)
        update_less_year_days(start_date, end_date, current_year)
        # 清除所有的违规记录
        VacationViolation.destroy_all
      when 7
        start_date = Time.parse("#{last_year}-7-1 00:00:00")
        end_date = Time.parse("#{last_year}-12-31 24:00:00")
        update_less_year_days(start_date, end_date, current_year)
        fix_year_days(last_year, current_year)
      end

      # update_less_year_days(start_date, end_date, current_year)
    end
  end

  def self.month_working_days(month)
    start_date = Date.parse(month + '-01')
    end_date = start_date.end_of_month
    free_days = check_free_days(start_date, end_date)
    end_date.day - free_days.size
  end

  private

  # 计算年假
  def self.get_year_days(employee)
    judge_date_20 = Date.parse("#{Date.today.year}-01-01") - 20.year
    judge_date_10 = Date.parse("#{Date.today.year}-01-01") - 10.year
    return 0 if employee.start_work_date.blank?

    if employee.start_work_date + employee.leave_days < judge_date_20
      return 15
    elsif employee.start_work_date + employee.leave_days >= judge_date_20 &&
      employee.start_work_date + employee.leave_days < judge_date_10
      return 10
    else
      return 5
    end
  end

  # 更新超过1年的员工的年假
  def self.update_over_year_days(current_year)
    return unless current_year

    Employee.where("join_scal_date < ?", "#{current_year.to_i - 1}-1-1").find_in_batches do |collection|
      collection.each do |employee|
        record = VacationRecord.find_or_initialize_by({employee_id: employee.id, year: current_year})
        record.init_days = record.days = get_year_days(employee)
        record.save!
      end
    end
  end

  # 更新入职不超过1年的员工的年假
  def self.update_less_year_days(start_date, end_date, current_year)
    return unless (start_date && end_date)

    Employee.where(join_scal_date: start_date..end_date).find_in_batches do |collection|
      collection.each do |employee|
        record = VacationRecord.find_or_initialize_by({employee_id: employee.id, year: current_year})
        record.init_days = record.days = get_year_days(employee)
        record.save!
      end
    end
  end

  # 处理上1年遗留的年假
  def self.fix_year_days(last_year, current_year)
    VacationRecord.where(year: last_year, record_type: '年假').each do |record|
      if record.days < 0
        condition = {employee_id: record.employee_id, year: current_year}
        fix_record = VacationRecord.where(condition).first
        fix_record.increment!(:days, record.days) if fix_record
      end

      record.destroy
    end
  end

  def self.check_free_days(start_date, end_date, easy_mode = true)
    free_days = []

    list = Date.range_list(start_date, end_date)

    if easy_mode
      exists = []

      list.each do |date|
        exists << date if [6, 0].include?(date.wday)
      end
    else
      exists = Holiday.where(record_date: list).map(&:record_date)
    end

    list.each {|x|free_days << x if exists.include?(x)}

    free_days
  end

  def self.month_first_natural_day(date)
    return date if date.day > 15
    count = self.check_free_days(date.beginning_of_month, date.prev_day, false).size
    count == date.day - 1 ? date.beginning_of_month : date
  end

  def self.first_working_date(month)
    start_date = Date.parse(month + "-01")
    end_date = Date.parse(month + "-01").end_of_month
    free_days = self.check_free_days(start_date, end_date, false)

    (start_date..end_date).to_a.each do |d|
      return d unless free_days.include?(d)
    end
  end
  
end

























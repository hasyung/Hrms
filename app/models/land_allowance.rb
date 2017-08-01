
class LandAllowance < ActiveRecord::Base
  serialize :short_days_list, Array
  serialize :metaphase_days_list, Array
  serialize :long_days_list, Array

  belongs_to :employee

  IMPORTOR_TYPE = {
    "FOC空勤数据" => :import_foc,
    "FOC飞行数据" => :import_foc
  }

  COLUMNS = %w(employee_no employee_name department_name position_name channel_id subsidy employee_id 
    month total add_garnishee notes remark locations days standard salary_set_book)

  def land_days_list
    hash = {}

    self.metaphase_days_list.each{|d|hash[d] = 1}
    self.long_days_list.each{|d|hash[d] = 2}
    self.short_days_list.each{|d|hash[d] = 3}

    hash
  end

  def self.compute_service(month)
    is_success, messages = AttendanceSummary.can_calc_salary?(month)
    return [is_success, messages] unless is_success

    service_channel_ids = CodeTable::Channel.where("display_name in (?)", %w(空勤 飞行)).map(&:id)
    # 先全部删除计算记录
    @remark_hash = LandAllowance.where("month = '#{month}' and channel_id in (?)", service_channel_ids).index_by(&:employee_id)

    @compute_date = Date.parse(month + '-01')

    # 人民币汇率设置
    @dollar_rate = Salary.where(category: 'global').first.form_data['dollar_rate']

    @land_subsidy_cities = {}
    @land_oversea_cities = []
    @general_amount      = 0

    Salary.where(category: 'land_subsidy').first.form_data.each do |key, item|
      (item['cities'] || []).each do |city|
        @land_subsidy_cities[city] = item['amount']
      end

      if key == 'general'
        # 普通
        @general_amount = item['amount']
      end

      if key.include?('overseas')
        @land_oversea_cities << item['cities']
        @land_oversea_cities.flatten!
      end
    end

    @airline_subsidy = Salary.where(category: 'airline_subsidy').first.form_data
    # 国内中长期标准
    @airline_inland_times = @airline_subsidy['inland_subsidy']

    @airline_outland_cities = {}
    # 国外餐食标准(刀)
    @airline_subsidy['outland_areas'].each do |item|
      @airline_outland_cities[item['city']] = item['outland_subsidy'] * @dollar_rate
    end

    # FOC表记录，要导入2次，国内和国外
    @all_records = LandRecord.where(month: month)

    # 所有的派驻异动，每个员工可能有多条记录
    @all_states = SpecialState.where(special_category: '派驻')

    t1 = Time.new

    LandAllowance.transaction do
      @values = []
      @calc_values = []

      Employee.where("employees.channel_id in (?)", service_channel_ids)
        .includes(:hours_fees, :special_states, :salary_person_setup, :channel, :department, :master_positions, :labor_relation, :attendance_summaries)
        .find_in_batches(batch_size: 3000).with_index do |group, batch|
        group.each do |employee|
          @setup = employee.salary_person_setup
          next unless @setup
          next if @setup.try(:is_special_category)
          next if employee.is_service_a?

          # raise "#{employee.name} 缺少薪酬设置" if !employee.salary_person_setup

          @fee = 0

          @short_days_list = []
          @metaphase_days_list = []
          @long_days_list = []

          hash = {employee_id: employee.id, category: 'land_allowance', month: month}
          calc_step = CalcStep.new(hash)

          special_states = employee.special_states.select{|s| s.special_category == "空勤停飞"}
          fly_hours = employee.hours_fees.select{|h| h.month == month}.map(&:fly_hours).map(&:to_f).inject(:+).to_f

          if employee.is_trainee?
            calc_step.push_step("实习生津贴为 0")
          elsif employee.is_fly_channel? && SpecialState.personal_stop_fly_months(special_states, month) > 5
            calc_step.push_step("因个人原因空勤停飞的第 6 个月仅有基本工资，驻站津贴为 0")
          elsif fly_hours == 0
            calc_step.push_step("空勤或飞行全月未飞，驻站津贴为 0(依据是小时费导入表的承包时间为0)")
          else
            @vacation_dates = employee.get_personal_leave_dates(month)
            @no_personal_vacation_dates = employee.get_no_personal_leave_dates(month)

            # 飞行和空勤通道计划中长期派驻
            @states = @all_states.where(employee_id: employee.id).order(:special_date_from)

            # FOC派驻表
            @records = @all_records.where(employee_name: employee.name).order(:start_day)

            # 驻站类型标记hash表
            @date_list_hash = {}
            # 驻站地hash表
            @location_list_hash = {}
            # 境外hash表
            @date_outland_fee_hash = {}
            # 请假1天是否已经压栈
            @vacation_pushed = []
            # 中长期驻站期间对应的缺席天数
            @metaphase_absent_days = @long_absent_days = 0

            # 遍历当前工资月份的每个日期，把驻站类型打上标记1, 2, 0 (default)
            # 这样在records foc表中就很容易的剔除掉中长期驻站，剩下的就是 3 短期派驻
            (@compute_date.beginning_of_month..@compute_date.end_of_month).to_a.each do |d|
              # 0 不是驻站 # 1 中期 # 2 长期 # 3 短期
              @states.each do |s|
                # 时间重合度
                next if (s.special_date_to && s.special_date_to < @compute_date.beginning_of_month) || s.special_date_from > @compute_date.end_of_month
                # 排除属地化
                next if employee.location == s.special_location

                if d >= s.special_date_from && (s.special_date_to.blank? || (s.special_date_to && d <= s.special_date_to))
                  @date_list_hash[d] = 0
                  @location_list_hash[d] = s.special_location


                  if s.special_date_to && s.is_metaphase_send?
                    @date_list_hash[d] = 1
                  elsif s.special_date_to.blank? || s.is_long_send?
                    @date_list_hash[d] = 2
                  else
                    if s.is_metaphase_send?
                      @date_list_hash[d] = 1
                    elsif s.is_long_send?
                      @date_list_hash[d] = 2
                    end
                  end

                  rate = 1
                  rate = 0.5 if @vacation_dates[d].to_i == 0.5

                  # 境外餐补?
                  if @airline_outland_cities.keys.include?(s.special_location)
                    @date_outland_fee_hash[d] = (@airline_outland_cities[s.special_location] * rate)
                  end
                end

                if @vacation_dates[d].to_i == 1 && !@vacation_pushed.include?(d)
                  @vacation_pushed << d
                end
              end
            end

            # 中长期驻站天数
            @metaphase_days = @longs_days = 0

            # 中长期驻站总天数
            @metaphase_full_days = @long_full_days = 0

            @states.each do |state|
              # 时间重合度
              next if (state.special_date_to && state.special_date_to < @compute_date.beginning_of_month) || state.special_date_from > @compute_date.end_of_month

              # 排除属地化
              if employee.location == state.special_location
                calc_step.push_step("员工属地 #{employee.location} 和 派驻地 #{state.special_location} 相同，忽略")
                next
              end

              state.special_date_to ||= @compute_date.end_of_month
              (state.special_date_from..state.special_date_to).to_a.each do |d|
                next unless @date_list_hash[d].present?

                if @date_list_hash[d] == 1
                  if employee.location != state.special_location
                    calc_step.push_step("员工属地 #{employee.location}，派驻地 #{state.special_location} #{d} 属于中期驻站，境外? #{@date_outland_fee_hash[d].present?}")
                    @metaphase_full_days += 1

                    rate = 1

                    if @vacation_dates[d] 
                      if employee.is_fly_channel?
                        calc_step.push_step("日期 #{d} 请事假或旷工天数 #{@vacation_dates[d].to_f}")
                      else
                        calc_step.push_step("日期 #{d} 请假或旷工天数 #{@vacation_dates[d].to_f}")
                      end
                      rate -= @vacation_dates[d].to_f
                    end

                    if @no_personal_vacation_dates[d].present?
                      # 非事假+非旷工需要累计驻站外出溜达天数
                      if employee.is_fly_channel?
                        @metaphase_absent_days += @no_personal_vacation_dates[d].to_f
                      else
                        rate -= @no_personal_vacation_dates[d].to_f
                        calc_step.push_step("日期 #{d} 请假或旷工天数 #{@no_personal_vacation_dates[d].to_f}")
                      end
                    end

                    @metaphase_days += rate
                  end
                elsif @date_list_hash[d] == 2
                  if employee.location != state.special_location
                    calc_step.push_step("员工属地 #{employee.location}，派驻地 #{state.special_location} #{d} 属于长期驻站，境外? #{@date_outland_fee_hash[d].present?}")
                    @long_full_days += 1

                    rate = 1

                    if @vacation_dates[d]
                      if employee.is_fly_channel?
                        calc_step.push_step("日期 #{d} 请事假或旷工天数 #{@vacation_dates[d].to_f}")
                      else
                        calc_step.push_step("日期 #{d} 请假或旷工天数 #{@vacation_dates[d].to_f}")
                      end
                      rate -= @vacation_dates[d].to_f
                    end

                    if @no_personal_vacation_dates[d].present?
                      # 非事假+非旷工需要累计驻站外出溜达天数
                      if employee.is_fly_channel?
                        @long_absent_days += @no_personal_vacation_dates[d].to_f
                      else
                        rate -= @no_personal_vacation_dates[d].to_f
                        calc_step.push_step("日期 #{d} 请假或旷工天数 #{@no_personal_vacation_dates[d].to_f}")
                      end
                    end

                    @longs_days += rate
                  end
                end
              end
            end

            @short_day_amount = @metaphase_amount = @longs_amount = 0

            if employee.is_fly_channel?
              calc_step.push_step("分类是飞行")
              @short_day_amount = @airline_inland_times['airline']['general']
              @metaphase_amount = @airline_inland_times['airline']['metaphase']
              @longs_amount = @airline_inland_times['airline']['long_term']
            elsif employee.classification == '空保'
              calc_step.push_step("分类是空保")
              @short_day_amount = @airline_inland_times['air_security']['general']
              @metaphase_amount = @airline_inland_times['air_security']['metaphase']
              @longs_amount = @airline_inland_times['air_security']['long_term']
            elsif employee.classification == '空乘' || employee.classification.blank? || employee.classification == '无'
              calc_step.push_step("分类是空乘")
              @short_day_amount = @airline_inland_times['cabin']['general']
              @metaphase_amount = @airline_inland_times['cabin']['metaphase']
              @longs_amount = @airline_inland_times['cabin']['long_term']
            else
              calc_step.push_step("提示: 员工既不是飞行通道，分类也不是空乘和空保，驻站标准以 0 计算，请核对员工基础数据")
            end

            # 计算短期驻站天数
            @short_days = 0

            @records.each do |record|
              start_date = Date.parse(month + "-#{[record.start_day, @compute_date.end_of_month.day].min}")
              end_date = Date.parse(month + "-#{[record.end_day, @compute_date.end_of_month.day].min}")

              (start_date..end_date).to_a.each do |d|
                # FOC表短期驻站不可能同时请假, 中长期的状态离开了驻站地(非事假旷工+因公等等)
                # 因公的条件是必须要回到员工的属地化地点
                if @date_list_hash[d].to_i == 1 && @location_list_hash[d] != record.city
                  @metaphase_absent_days += 1 if record.city == employee.location
                elsif @date_list_hash[d].to_i == 2 && @location_list_hash[d] != record.city
                  @long_absent_days += 1 if record.city == employee.location
                end

                if @date_list_hash[d].to_i <= 0 && employee.location != record.city
                  @date_list_hash[d] = 3
                  @short_days += 1
                  calc_step.push_step("日期 #{d} 属于短期驻站，派驻地 #{record.city}，境外? #{@airline_outland_cities[record.city].present?}")

                  if @airline_outland_cities.keys.include?(record.city)
                    @date_outland_fee_hash[d] = @airline_outland_cities[record.city]
                  end
                end
              end
            end

            summary = employee.attendance_summaries.select{|s| s.summary_date == month}.first
            calc_step.push_step("本月培训 #{summary.cultivate.to_f} 天， 疗养假 #{summary.recuperate_leave.to_f} 天， 计划生育假 #{summary.family_planning_leave.to_f} 天")
            if @metaphase_days > 0
              @enable_days = (@metaphase_full_days / 3.0).round
              @metaphase_absent_days += summary.cultivate.to_f
              if employee.is_fly_channel?
                @metaphase_absent_days += summary.recuperate_leave.to_f + summary.family_planning_leave.to_f
              else
                @metaphase_days -= summary.recuperate_leave.to_f + summary.family_planning_leave.to_f
              end
              @bad_days = @metaphase_absent_days - @enable_days

              if @bad_days > 0
                if employee.is_fly_channel?
                  calc_step.push_step("中期驻站计划天数(不包含事假或旷工) #{@metaphase_days}, 允许复训、因公外出等非事假或旷工天数 #{@enable_days}, 实际天数是 #{@metaphase_absent_days}")
                else
                  calc_step.push_step("中期驻站计划天数(不包含培训外考勤) #{@metaphase_days}, 允许复训、因公外出等非培训外考勤天数 #{@enable_days}, 实际天数是 #{@metaphase_absent_days}")
                end
                @metaphase_days -= @bad_days
                calc_step.push_step("中期驻站扣减天数 #{@bad_days}，最后实际天数 #{@metaphase_days}")
              end

              temp_fee = (@metaphase_amount.to_f / @compute_date.end_of_month.day * @metaphase_days).round(2)
              calc_step.push_step("中期驻站标准 #{@metaphase_amount}/月，折算为 #{temp_fee}")
              @fee += temp_fee
            end

            if @longs_days > 0
              if employee.is_fly_channel?
                @enable_days = (@long_full_days / 2.0).round
              else
                @enable_days = (@long_full_days / 3.0).round
              end
              @long_absent_days += summary.cultivate.to_f
              if employee.is_fly_channel?
                @long_absent_days += summary.recuperate_leave.to_f + summary.family_planning_leave.to_f
              else
                @longs_days -= summary.recuperate_leave.to_f + summary.family_planning_leave.to_f
              end
              @bad_days = @long_absent_days - @enable_days

              if @bad_days > 0
                if employee.is_fly_channel?
                  calc_step.push_step("长期驻站计划天数(不包含事假或旷工) #{@longs_days}, 允许复训、因公外出等非事假或旷工天数 #{@enable_days}, 实际天数是 #{@long_absent_days}")
                else
                  calc_step.push_step("长期驻站计划天数(不包含培训外考勤) #{@longs_days}, 允许复训、因公外出等非培训外考勤天数 #{@enable_days}, 实际天数是 #{@long_absent_days}")
                end
                @longs_days -= @bad_days
                calc_step.push_step("长期驻站扣减天数 #{@bad_days}，最后天数 #{@longs_days}")
              end

              temp_fee = (@longs_amount.to_f / @compute_date.end_of_month.day * @longs_days).round(2)
              calc_step.push_step("长期驻站标准 #{@longs_amount}/月，折算为 #{temp_fee}")
              @fee += temp_fee
            end

            temp_fee = (@short_days * @short_day_amount).round(2)
            @fee += temp_fee

            if @short_days > 0
              calc_step.push_step("短期驻站天数 #{@short_days}")
              calc_step.push_step("短期驻站标准 #{@short_day_amount}，补贴为 #{temp_fee}")
            end

            calc_step.push_step("所有补贴总金额为 #{@fee}")
          end

          @total = @fee
          calc_step.push_step("所有驻站补贴金额最后总计是 #{@total}")

          calc_step.final_amount(@total)

          @notes = employee.get_vacation_desc(month).try(:values).try(:join, ", ").to_s
          @values << [
            employee.employee_no, employee.name, employee.department.full_name,
            employee.master_position.name, employee.channel_id, @fee,
            employee.id, month, @total,
            @remark_hash[employee.id].try(:add_garnishee).to_f, @notes,
            @remark_hash[employee.id].try(:remark),
            @locations,
            @record_days,
            @standard,
            employee.salary_set_book
          ]
          @calc_values << [calc_step.employee_id, calc_step.month, calc_step.category, calc_step.step_notes, calc_step.amount]
        end
      end

      land_allowances = LandAllowance.where("month = '#{month}' and channel_id in (?)", service_channel_ids)
      CalcStep.where("month='#{month}' and category='land_allowance' and employee_id in (?)", land_allowances.map(&:employee_id)).delete_all
      land_allowances.delete_all

      CalcStep.import(CalcStep::COLUMNS, @calc_values, validate: false)
      LandAllowance.import(COLUMNS, @values, validate: false)
    end

    t2 = Time.new
    puts "计算耗费 #{t2 - t1} 秒"

    return true
  end

  def self.compute_land(month)
    is_success, messages = AttendanceSummary.can_calc_salary?(month)
    return [is_success, messages] unless is_success

    service_channel_ids = CodeTable::Channel.where("display_name in (?)", %w(空勤 飞行)).map(&:id)
    # 先全部删除计算记录
    @remark_hash = LandAllowance.where("month = #{month} and channel_id not in (?)", service_channel_ids).index_by(&:employee_id)

    @compute_date = Date.parse(month + '-01')

    @land_subsidy_cities = {}
    @land_oversea_cities = []
    @general_amount      = 0

    Salary.where(category: 'land_subsidy').first.form_data.each do |key, item|
      (item['cities'] || []).each do |city|
        @land_subsidy_cities[city] = item['amount']
      end

      if key == 'general'
        # 普通
        @general_amount = item['amount']
      end

      if key.include?('overseas')
        @land_oversea_cities << item['cities']
        @land_oversea_cities.flatten!
      end
    end

    @airline_subsidy = Salary.where(category: 'airline_subsidy').first.form_data
    # 国内中长期标准
    @airline_inland_times = @airline_subsidy['inland_subsidy']

    # FOC表记录，要导入2次，国内和国外
    @all_records = LandRecord.where(month: month)

    # 所有的派驻异动，每个员工可能有多条记录
    @all_states = SpecialState.where(special_category: '派驻')

    t1 = Time.new

    LandAllowance.transaction do
      @values = []
      @calc_values = []

      Employee.where("employees.channel_id not in (?)", service_channel_ids)
        .includes(:special_states, :salary_person_setup, :channel, :department, :master_positions, :labor_relation)
        .find_in_batches(batch_size: 3000).with_index do |group, batch|
        group.each do |employee|
          @setup = employee.salary_person_setup
          next unless @setup
          next if @setup.try(:is_special_category)
          next if employee.is_service_a?


          # raise "#{employee.name} 缺少薪酬设置" if !employee.salary_person_setup

          @fee = 0

          @short_days_list = []
          @metaphase_days_list = []
          @long_days_list = []
          locations, standard, record_days = nil, nil, nil

          hash = {employee_id: employee.id, category: 'land_allowance', month: month}
          calc_step = CalcStep.new(hash)

          if employee.is_trainee?
            calc_step.push_step("实习生津贴为 0")
            @fee = 0
          else
            @vacation_dates = employee.get_vacation_dates(month)

            # 普通
            calc_step.push_step("属于地面驻站设置")
            # 导入的数据都是FOC的，飞行和空勤才有，地面驻站就不用看导入数据了

            @states = @all_states.where(employee_id: employee.id).order(:special_date_from)

            @states.each do |state|
              next if (state.special_date_to && state.special_date_to < @compute_date.beginning_of_month) || state.special_date_from > @compute_date.end_of_month
              calc_step.push_step("员工属地 #{employee.location}，派驻点 #{state.special_location}, 从 #{state.special_date_from} 到 #{state.special_date_to || '无结束日期'}")

              if employee.location == state.special_location
                calc_step.push_step("员工属地和派驻地相同，忽略")
                next
              end

              # 派驻地补贴标准
              @location_amount = @land_subsidy_cities[state.special_location]

              if !@location_amount
                # raise "地面派驻点 #{state.special_location} 的补贴标准未设置，请完善设置"
                calc_step.push_step("派驻点 #{state.special_location} 的补贴标准未设置，使用通用标准 #{@general_amount}")
                @location_amount = @general_amount
              elsif @land_oversea_cities.include?(state.special_location)
                if state.special_date_to.blank? || state.not_full_months(month) > 5
                  @location_amount = 0
                  calc_step.push_step("派驻点 #{state.special_location} 为境外区域，派驻总时长超过六个月(含)或派驻结束时间未定的，标准为 0")
                else
                  calc_step.push_step("派驻点 #{state.special_location} 为境外区域，标准为 #{@location_amount}")
                end
              else
                calc_step.push_step("派驻点 #{state.special_location} 非境外区域，标准为 #{@location_amount}")
              end

              @days = 0

              start_date = [@compute_date.beginning_of_month, state.special_date_from].max
              end_date = [@compute_date.end_of_month, state.special_date_to || @compute_date.end_of_month].min

              (start_date..end_date).to_a.each do |d|
                if @vacation_dates[d].present?
                  if @vacation_dates[d] == 0.5
                    calc_step.push_step("日期 #{d} 请假或旷工天数 0.5")
                    @days += 0.5
                  else
                    calc_step.push_step("日期 #{d} 请假或旷工天数 1.0")
                  end
                else
                  @days += 1
                end
              end

              locations = locations ? locations + ", #{state.special_location}" : "#{state.special_location}"
              standard = standard ? standard + ", #{@location_amount.to_f}" : "#{@location_amount.to_f}"
              record_days = record_days ? record_days + ", #{@days}" : "#{@days}"

              @fee += @location_amount * @days
              calc_step.push_step("当月派驻天数 #{@days}，补贴金额是 #{@location_amount * @days}")
              calc_step.push_step("补贴金额累计是 #{@fee}")
            end
          end

          @total = @fee
          calc_step.push_step("所有驻站补贴金额最后总计是 #{@total}")

          # @total += @remark_hash[employee.id].try(:add_garnishee).to_f
          calc_step.final_amount(@total)

          @notes = employee.get_vacation_desc(month).try(:values).try(:join, ", ").to_s
          @values << [
            employee.employee_no, employee.name, employee.department.full_name,
            employee.master_position.name, employee.channel_id, @fee,
            employee.id, month, @total,
            @remark_hash[employee.id].try(:add_garnishee).to_f, @notes,
            @remark_hash[employee.id].try(:remark),
            locations,
            record_days,
            standard,
            employee.salary_set_book
          ]
          @calc_values << [calc_step.employee_id, calc_step.month, calc_step.category, calc_step.step_notes, calc_step.amount]
        end
      end

      land_allowances = LandAllowance.where("month = '#{month}' and channel_id not in (?)", service_channel_ids)
      CalcStep.where("month='#{month}' and category='land_allowance' and employee_id in (?)", land_allowances.map(&:employee_id)).delete_all
      land_allowances.delete_all

      CalcStep.import(CalcStep::COLUMNS, @calc_values, validate: false)
      LandAllowance.import(COLUMNS, @values, validate: false)
    end

    t2 = Time.new
    puts "计算耗费 #{t2 - t1} 秒"

    return true
  end
end

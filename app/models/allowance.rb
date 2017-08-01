class Allowance < ActiveRecord::Base
  belongs_to :employee

  IMPORTOR_TYPE = {
    "航线实习补贴"  => :import_airline_practice,
    "随机补贴"      => :import_follow_plane,
    "签派放行补贴"  => :import_permit_sign,
    "梭班补贴"      => :import_work_overtime,
    "物业补贴"     =>  :import_property_subsidy,
    "执勤补贴"     =>  :import_import_on_duty_subsidy,
    "代泊车补贴"   =>  :import_with_parking_subsidy,
    "年审补贴"     =>  :import_annual_audit_subsidy,
    "航材搬运补贴"  =>  :import_material_handling_subsidy
  }

  COLUMNS = %w(employee_id employee_name employee_no department_name
    position_name channel_id month security_check resettlement group_leader
    air_station_manage car_present land_present permit_entry try_drive fly_honor
    building_subsidy retiree_clean_fee maintain_subsidy on_duty_subsidy
    airline_practice follow_plane permit_sign work_overtime property_subsidy
    import_on_duty_subsidy with_parking_subsidy annual_audit_subsidy temp cold
    communication total add_garnishee notes remark salary_set_book
    flyer_science_money security_check_standard group_leader_standard
    car_present_standard land_present_standard permit_entry_standard
    try_drive_standard part_permit_entry_standard part_permit_entry
    resettlement_standard fly_honor_standard communication_standard
    cq_part_time_fix_car_subsidy cq_part_time_fix_car_subsidy_standard
    air_station_manage_standard watch_subsidy logistical_support_subsidy material_handling_subsidy
  )

  validates :month, uniqueness: { scope: [:month, :employee_id] }

  def self.compute(month)
    is_success, messages = AttendanceSummary.can_calc_salary?(month)
    return [is_success, messages] unless is_success

    @allowance_records = AllowanceRecord.where(month: month).index_by(&:employee_name)
    @setting = Salary.where(category: 'allowance').first.form_data

    # 先全部删除计算记录
    @remark_hash = Allowance.where(month: month).index_by(&:employee_id)

    t1 = Time.new

    Allowance.transaction do
      @values = []
      @calc_values = []

      Employee.includes(:special_states, :salary_person_setup, :channel, :department, :master_positions, :labor_relation, :positions).find_in_batches(batch_size: 3000).with_index do |group, batch|
        group.each do |employee|
          @setup = employee.salary_person_setup
          next unless @setup
          next if @setup.try(:is_special_category)
        #  next if employee.is_service_a?  ###服务a的人也要算津贴

          return [false, "#{employee.name} 非实习人员但到岗时间为空"] if employee.join_scal_date.blank? && !employee.is_trainee?

          # raise "#{employee.name} 缺少薪酬设置" if !employee.salary_person_setup

          hash = {employee_id: employee.id, category: 'allowance', month: month}
          calc_step = CalcStep.new(hash)

          special_states = employee.special_states.select{|s| s.special_category == "空勤停飞"}

          @security_check_standard     = @setting['security_subsidy'][@setup.security_subsidy].to_f
          @group_leader_standard       = @setting['leader_subsidy'][@setup.leader_subsidy]
          @car_present_standard        = @setting['car_subsidy'].to_f
          @land_present_standard       = @setting['ground_subsidy'][@setup.ground_subsidy].to_f
          @permit_entry_standard       = @setting['machine_subsidy'][@setup.machine_subsidy].to_f
          @try_drive_standard          = @setting['trial_subsidy'][@setup.trial_subsidy].to_f
          @fly_honor_standard          = @setting['honor_subsidy'][@setup.honor_subsidy].to_f
          @resettlement_standard       = @setting['placement_subsidy'].to_f
          @part_permit_entry_standard  = @setting['part_permit_entry'].to_f
          @cq_part_time_fix_car_subsidy_standard = @setting['cq_part_time_fix_car_subsidy'][@setup.cq_part_time_fix_car_subsidy].to_f
          @air_station_manage_standard = @setting['terminal_subsidy'][@setup.terminal_subsidy].to_f

          # 通讯补贴
          if @setup.communicate_allowance.present?
            @communication_standard = @setup.communicate_allowance
          else
            position_communication_fee = employee.positions.map(&:communicate_allowance).map(&:to_f).max
            duty_rank_communication_fee = employee.duty_rank.try(:communicate_allowance).to_f
            @communication_standard = [position_communication_fee, duty_rank_communication_fee].max
          end

          #if employee.is_trainee?
            # 实习生
          #  calc_step.push_step("实习生津贴为 0")
          #  @security_subsidy = @leader_subsidy = @terminal_subsidy = @ground_subsidy = @machine_subsidy = @trial_subsidy = @honor_subsidy = @airline_practice = @follow_plane = @permit_sign = @work_overtime = @placement_subsidy = @car_subsidy = @temp_fee = @cold_fee = @communication_fee = @part_permit_entry = @cq_part_time_fix_car_subsidy = @material_handling_subsidy = 0
          #  @total = 0

            join_date =  employee.join_scal_date.blank? ?  employee.start_internship_date : employee.join_scal_date 

          if employee.is_fly_channel? && SpecialState.personal_stop_fly_months(special_states, month) > 5
            calc_step.push_step("因个人原因空勤停飞的第 6 个月仅有基本工资，津贴为 0")
            @security_subsidy = @leader_subsidy = @terminal_subsidy = @ground_subsidy = @machine_subsidy = @trial_subsidy = @honor_subsidy = @airline_practice = @follow_plane = @permit_sign = @work_overtime = @placement_subsidy = @car_subsidy = @temp_fee = @cold_fee = @communication_fee = @part_permit_entry = @cq_part_time_fix_car_subsidy = @material_handling_subsidy = @flyer_science_money = 0
            @total = 0
          elsif join_date.strftime("%Y-%m") == month && VacationRecord.month_first_natural_day(join_date)
            # 新进处理 (除了实习，入川航的时间必须有)
            calc_step.push_step("新进员工入川航的时间不是当月 #{month} 第1天上班，次月才发津贴")
            @security_subsidy = @leader_subsidy = @terminal_subsidy = @ground_subsidy = @machine_subsidy = @trial_subsidy = @honor_subsidy = @airline_practice = @follow_plane = @permit_sign = @work_overtime = @placement_subsidy = @car_subsidy = @temp_fee = @cold_fee = @communication_fee = @part_permit_entry = @cq_part_time_fix_car_subsidy = @material_handling_subsidy = @flyer_science_money = 0
            @total = 0
          else
            @temp_fee = calc_temperature(employee, month, calc_step) #高温补贴

            @cold_fee = calc_cold_subsidy(employee, month, calc_step) #寒冷补贴

            # 通讯补贴
            if @setup.communicate_allowance.present?
              @communication_fee = @setup.communicate_allowance
            else
              @position_communication_fee = employee.positions.map(&:communicate_allowance).map(&:to_f).max
              @duty_rank_communication_fee = employee.duty_rank.try(:communicate_allowance).to_f
              @communication_fee = [@position_communication_fee, @duty_rank_communication_fee].max
            end
            calc_step.push_step("通讯补贴(岗位与职务职级就高，薪酬个人设置优先): #{@communication_fee}")

            # 当月请假天数
            vacation_days = employee.get_vacation_days(month)

            if employee.full_month_vacation?(month)
              calc_step.push_step("全月不在岗通讯补贴为 0")
              @communication_fee = 0
            elsif employee.is_fly_channel? || employee.is_air_service_channel?
              calc_step.push_step("属于飞行或者空勤通道")


              start_month = (month + '-01').to_date.beginning_of_month
              end_month = (month + '-01').to_date.end_of_month
              is_full_land_work = employee.special_states.select{|s| s.special_category == '空勤地面' &&
                (s.special_date_from <= start_month && (s.special_date_to.blank? || s.special_date_to >=
                end_month))}.present?

              if is_full_land_work && (employee.duty_rank.blank? || employee.duty_rank.display_name == '无')
                calc_step.push_step("无职务职级的空勤通道人员，上地面行政班通讯补贴为 0")
                @communication_fee = 0
              else
                # 请假或者空勤停飞的天数
                @vacation_stop_fly_days = 0

                @date_list_hash = employee.get_vacation_dates(month)
                special_states.each do |state|
                  array = nil
                  if state.special_date_to.blank?
                    array = state.special_date_from..Date.parse(month + "-01").end_of_month
                  else
                    array = state.special_date_from..state.special_date_to
                  end
                  array.to_a.each do |d|
                    @date_list_hash[d] = 1
                  end
                end

                (Date.parse(month + "-01")..Date.parse(month + "-01").end_of_month).to_a.each do |d|
                  calc_step.push_step("日期 #{d} 请假或者空勤停飞 #{@date_list_hash[d].to_f}")
                  @vacation_stop_fly_days += @date_list_hash[d].to_f
                end

                if @vacation_stop_fly_days >= Date.parse(month + "-01").end_of_month.day
                  calc_step.push_step("当月请假和空勤停飞天数大于等于当月总天数，通讯补贴为 0")
                  @communication_fee = 0
                elsif @vacation_stop_fly_days > 15
                  calc_step.push_step("当月请假和空勤停飞天数大于 15 天，通讯补贴发一半")
                  @communication_fee = @communication_fee * 0.5
                end
              end
            elsif vacation_days > 15
              calc_step.push_step("当月请假天数大于 15 天，通讯补贴发一半")
              @communication_fee = @communication_fee * 0.5
            end

            # 安检津贴
            @security_subsidy = @setting['security_subsidy'][@setup.security_subsidy].to_f
            calc_step.push_step("安检津贴 #{@security_subsidy.to_f}")

            # 班组长津贴
            @leader_subsidy = @setting['leader_subsidy'][@setup.leader_subsidy]
            calc_step.push_step("班组长津贴 #{@leader_subsidy.to_f}")

            # 航站管理津贴
            @terminal_subsidy = @setting['terminal_subsidy'][@setup.terminal_subsidy].to_f
            calc_step.push_step("航站管理津贴 #{@terminal_subsidy.to_f}")

            # 地勤补贴
            # 合同、合同制的到岗三个月后的次月，正发
            # 劳务派遣的到岗三个月后的次月，倒发
            @ground_subsidy = @setting['ground_subsidy'][@setup.ground_subsidy].to_f
            calc_step.push_step("地勤补贴 #{@ground_subsidy.to_f}")

            # 机务放行补贴
            @machine_subsidy = @setting['machine_subsidy'][@setup.machine_subsidy].to_f
            calc_step.push_step("机务放行补贴 #{@machine_subsidy.to_f}")

            # 试车津贴
            @trial_subsidy = @setting['trial_subsidy'][@setup.trial_subsidy].to_f
            calc_step.push_step("试车津贴 #{@trial_subsidy.to_f}")

            # 飞行安全荣誉补贴
            @honor_subsidy = @setting['honor_subsidy'][@setup.honor_subsidy].to_f
            calc_step.push_step("飞行安全荣誉补贴 #{@honor_subsidy.to_f}")

            # 大厦补贴
            @building_subsidy = @setup.building_subsidy.to_f
            calc_step.push_step("大厦补贴 #{@building_subsidy}")

            # 退休人员清洁费
            @retiree_clean_fee = @setup.retiree_clean_fee.to_f
            calc_step.push_step("退休人员清洁费 #{@retiree_clean_fee}")

            # 维修补贴
            @maintain_subsidy = @setup.maintain_subsidy.to_f
            calc_step.push_step("维修补贴 #{@maintain_subsidy}")

            # 执勤补贴
            @on_duty_subsidy = @setup.on_duty_subsidy.to_f
            calc_step.push_step("执勤补贴 #{@on_duty_subsidy}")

            # 重庆兼职车辆维修班补贴
            @cq_part_time_fix_car_subsidy = @setting['cq_part_time_fix_car_subsidy'][@setup.cq_part_time_fix_car_subsidy].to_f
            calc_step.push_step("重庆兼职车辆维修班补贴 #{@cq_part_time_fix_car_subsidy}")

            # 导入的
            @airline_practice          = @allowance_records[employee.name].try(:airline_practice).to_f
            @follow_plane              = @allowance_records[employee.name].try(:follow_plane).to_f
            @permit_sign               = @allowance_records[employee.name].try(:permit_sign).to_f
            @work_overtime             = @allowance_records[employee.name].try(:work_overtime).to_f
            @property_subsidy          = @allowance_records[employee.name].try(:property_subsidy).to_f
            @import_on_duty_subsidy    = @allowance_records[employee.name].try(:import_on_duty_subsidy).to_f
            @with_parking_subsidy      = @allowance_records[employee.name].try(:with_parking_subsidy).to_f
            @annual_audit_subsidy      = @allowance_records[employee.name].try(:annual_audit_subsidy).to_f
            @material_handling_subsidy = @allowance_records[employee.name].try(:material_handling_subsidy).to_f
            calc_step.push_step("导入的补贴: 物业补贴 #{@property_subsidy} 导入执勤补贴 #{@import_on_duty_subsidy} 代泊车补贴 #{@with_parking_subsidy} 年审补贴 #{@annual_audit_subsidy}  航线实习补贴 #{@airline_practice.to_f}, 随机补贴 #{@follow_plane.to_f}, 签派放行补贴 #{@permit_sign.to_f}, 梭班补贴 #{@work_overtime.to_f}, 航材搬运补贴 #{@material_handling_subsidy.to_f}")

            # 安置津贴
            @placement_subsidy = @setting['placement_subsidy'].to_f
            # 车勤补贴
            @car_subsidy = @setting['car_subsidy'].to_f
            # 部件放行补贴
            @part_permit_entry = @setting['part_permit_entry'].to_f
            @watch_subsidy  = @setting['watch_subsidy'].to_f
            @logistical_support_subsidy  = @setting['logistical_support_subsidy'].to_f

            calc_step.push_step("全局设置安置津贴是 #{@placement_subsidy}, 车勤补贴是 #{@car_subsidy}, 部件放行补贴 #{@part_permit_entry},
              值班工资是 #{@watch_subsidy}, 后勤保障部补贴是 #{@logistical_support_subsidy}")

            if !employee.is_contract_type_regulation?
              # 非合同、合同制的员工没有安置津贴
              calc_step.push_step('员工不是合同、合同制的员工没有安置津贴')
              @placement_subsidy = 0
            end

            if !@setup.placement_subsidy
              calc_step.push_step('员工个人薪酬设置设置安置津贴为无')
              @placement_subsidy = 0
            else
              calc_step.push_step("安置津贴 #{@placement_subsidy}")
            end

            if !@setup.car_subsidy
              calc_step.push_step('员工个人薪酬设置设置车勤津贴为无')
              @car_subsidy = 0
            else
              calc_step.push_step("车勤津贴 #{@car_subsidy}")
            end

            if !@setup.part_permit_entry
              calc_step.push_step('员工个人薪酬设置设置部件放行补贴为无')
              @part_permit_entry = 0
            else
              calc_step.push_step("部件放行补贴 #{@part_permit_entry}")
            end

            if !@setup.watch_subsidy
              calc_step.push_step('员工个人薪酬设置设置值班工资为无')
              @watch_subsidy = 0
            else
              calc_step.push_step("值班工资 #{@watch_subsidy}")
            end

            if !@setup.logistical_support_subsidy
              calc_step.push_step('员工个人薪酬设置设置后勤保障部补贴为无')
              @logistical_support_subsidy = 0
            else
              calc_step.push_step("后勤保障部补贴 #{@logistical_support_subsidy}")
            end


            if employee.full_month_vacation?(month)
              calc_step.push_step("全月 #{month} 不在岗，安检、班组长、航站管理、地勤、机务放行、车勤补助、高温补贴、寒冷补贴、执勤补贴、试车津贴  0")
              @security_subsidy  = 0
              @leader_subsidy    = 0
              @terminal_subsidy  = 0
              @ground_subsidy    = 0
              @machine_subsidy   = 0
              @part_permit_entry = 0
              @car_subsidy       = 0
              @temp_fee          = 0
              @cold_fee          = 0
              @on_duty_subsidy   = 0
              @trial_subsidy     = 0
            else
              # 倒发: 高温津贴、安检津贴、车勤补贴、地勤补贴、放行津贴、班组长津贴、航站管理津贴，空勤灶
              # 正发倒发看的考勤月份不一样
              if vacation_days > 15
                calc_step.push_step("累计不清零的请假天数 > 15 天，安检、班组长、航站管理、地勤、机务放行、车勤补助、执勤补贴、试车津贴 发一半")
                @security_subsidy  = @security_subsidy.to_f * 0.5
                @leader_subsidy    = @leader_subsidy.to_f * 0.5
                @terminal_subsidy  = @terminal_subsidy.to_f * 0.5
                @ground_subsidy    = @ground_subsidy.to_f * 0.5
                @machine_subsidy   = @machine_subsidy.to_f * 0.5
                @part_permit_entry = @part_permit_entry.to_f * 0.5
                @car_subsidy       = @car_subsidy.to_f * 0.5
                @on_duty_subsidy   = @on_duty_subsidy * 0.5
                @trial_subsidy     = @trial_subsidy * 0.5
              end
            end


            #飞行驾驶技术津贴
            @flyer_science_money = @setup.is_send_flyer_science ? @setup.try(:flyer_science_money).to_f : 0
            calc_step.push_step("飞行驾驶技术津贴补贴金额是 #{@flyer_science_money}")

            @total = @security_subsidy.to_f + @placement_subsidy.to_f + @leader_subsidy.to_f +
              @terminal_subsidy.to_f + @car_subsidy.to_f + @ground_subsidy.to_f +
              @machine_subsidy.to_f + @trial_subsidy.to_f + @honor_subsidy.to_f +
              @airline_practice.to_f + @follow_plane.to_f + @permit_sign.to_f +
              @work_overtime.to_f + @temp_fee.to_f + @cold_fee.to_f + @communication_fee.to_f +
              @flyer_science_money.to_f + @building_subsidy.to_f + @retiree_clean_fee.to_f +
              @maintain_subsidy.to_f + @on_duty_subsidy.to_f + @property_subsidy.to_f +
              @import_on_duty_subsidy.to_f + @with_parking_subsidy.to_f + @annual_audit_subsidy.to_f +
              @part_permit_entry.to_f + @cq_part_time_fix_car_subsidy.to_f + @watch_subsidy +
              @logistical_support_subsidy + @material_handling_subsidy

            # @total += @remark_hash[employee.id].try(:add_garnishee).to_f
          end

          calc_step.final_amount(@total)
          @notes = employee.get_vacation_desc(month).try(:values).try(:join, ", ").to_s
          @values << [employee.id,
             employee.name,
             employee.employee_no,
             employee.department.full_name,
             employee.master_position.name,
             employee.channel_id,
             month,
             # 薪酬个人设置补贴
             @security_subsidy.to_f,
             @placement_subsidy.to_f,
             @leader_subsidy.to_f,
             @terminal_subsidy.to_f,
             @car_subsidy.to_f,
             @ground_subsidy.to_f,
             @machine_subsidy.to_f,
             @trial_subsidy.to_f,
             @honor_subsidy.to_f,
             @building_subsidy.to_f,
             @retiree_clean_fee.to_f,
             @maintain_subsidy.to_f,
             @on_duty_subsidy.to_f,
             # 还有4个导入补贴
             @airline_practice.to_f,
             @follow_plane.to_f,
             @permit_sign.to_f,
             @work_overtime.to_f,
             @property_subsidy.to_f,
             @import_on_duty_subsidy.to_f,
             @with_parking_subsidy.to_f,
             @annual_audit_subsidy.to_f,
             @temp_fee, # 高温补贴
             @cold_fee, # 寒冷补贴
             @communication_fee,
             @total,
             @remark_hash[employee.id].try(:add_garnishee).to_f,
             @notes,
             @remark_hash[employee.id].try(:remark),
             employee.salary_set_book,
             @flyer_science_money,
             @security_check_standard.to_f,
             @group_leader_standard.to_f,
             @car_present_standard.to_f,
             @land_present_standard.to_f,
             @permit_entry_standard.to_f,
             @try_drive_standard.to_f,
             @part_permit_entry_standard.to_f,
             @part_permit_entry.to_f,
             @resettlement_standard.to_f,
             @fly_honor_standard.to_f,
             @communication_standard.to_f,
             @cq_part_time_fix_car_subsidy.to_f,
             @cq_part_time_fix_car_subsidy_standard.to_f,
             @air_station_manage_standard,
             @watch_subsidy,
             @logistical_support_subsidy,
             @material_handling_subsidy
          ]
          @calc_values << [calc_step.employee_id, calc_step.month, calc_step.category, calc_step.step_notes, calc_step.amount]
        end
      end

      Allowance.where(month: month).delete_all
      CalcStep.remove_items('allowance', month)

      CalcStep.import(CalcStep::COLUMNS, @calc_values, validate: false)
      Allowance.import(COLUMNS, @values, validate: false)

      @calc_values.clear
      @values.clear
    end

    t2 = Time.new
    puts "计算耗费 #{t2 - t1} 秒"

    return true
  end

  def self.calc_cold_subsidy(employee, month, calc_step) #计算寒冷补贴
    @cold_subsidy_amount = 0

    @date          = Date.parse(month + '-01')
    @start_date    = @date.beginning_of_month
    @end_date      = @date.end_of_month
    @compute_month = @date.month

    @cold_subsidy_type = employee.positions.map(&:cold_subsidy_type).uniq.delete_if {|item| item == ""}.min #寒冷补贴类型
    @location = employee.location #员工属地

    @city_config = load_cold_subsidy_config(@compute_month)
    @amount_config = load_cold_subsidy_amount_config

    case @cold_subsidy_type
    when "A"
      calc_step.push_step("员工寒冷补贴类型的为:甲类员工, 以下为计算过程:")

      vacation_days, vacation_days_hash   = calc_vacation_days(employee, month)
      location_days_hash, study_days_list = calc_cold_subsidy_days(employee, @location, month)

      study_vacation_days_list = study_days_list | vacation_days_hash.keys

      location_vacation_days = location_days_hash.keys & study_vacation_days_list

      (@start_date..@end_date).to_a.each do |day|
        if location_vacation_days.include?(day)
          #派驻中，但是请假或者离岗培训
          @send_location = location_days_hash[day]
          if vacation_days_hash[day].present? && vacation_days_hash[day].to_f < 1
            if has_highland_cold_subsidy?(@send_location, month)
              calc_step.push_step("#{day.to_s} 当日派驻 #{@send_location}，因驻地享受高寒补贴, 当天寒冷补贴为: 0 元")
            else
              if @city_config[@send_location].present? && @city_config[@send_location][@cold_subsidy_type].present?
                per_day_amout =  (1 - vacation_days_hash[day].to_f) * @amount_config[@cold_subsidy_type][@city_config[@send_location][@cold_subsidy_type]]
                @cold_subsidy_amount = @cold_subsidy_amount + per_day_amout
                calc_step.push_step("#{day.to_s} 当日派驻 #{@send_location}，请假或旷工#{vacation_days_hash[day]}天, 当天寒冷补贴为 #{per_day_amout} 元")
              else
                calc_step.push_step("#{day.to_s} 当日派驻 #{@send_location}，请假或旷工#{vacation_days_hash[day]}天, 因驻地不享受寒冷补贴，当天寒冷补贴为 0 元")
              end
            end
          else
            calc_step.push_step("#{day.to_s} 当日派驻 #{@send_location}，但是处于请假或离岗培训, 当天寒冷补贴为: 0 元")
          end
          next
        end

        if location_days_hash.keys.include?(day)
          #派驻期间
          @send_location = location_days_hash[day]
          if has_highland_cold_subsidy?(@send_location, month)
            calc_step.push_step("#{day.to_s} 当日派驻 #{@send_location}，因驻地享受高寒补贴, 当天寒冷补贴为: 0 元")
          else
            if @city_config[@send_location].present? && @city_config[@send_location][@cold_subsidy_type].present?
              per_day_amout = @amount_config[@cold_subsidy_type][@city_config[@send_location][@cold_subsidy_type]]
              @cold_subsidy_amount = @cold_subsidy_amount + per_day_amout
              calc_step.push_step("#{day.to_s} 当日派驻 #{@send_location}，当天寒冷补贴为 #{per_day_amout} 元")
            else
              calc_step.push_step("#{day.to_s} 当日派驻 #{@send_location}，因驻地不享受寒冷补贴，当天寒冷补贴为 0 元")
            end
          end
          next
        end

        if study_vacation_days_list.include?(day)
          #请休假，离岗培训
          if has_highland_cold_subsidy?(@location, month)
            calc_step.push_step("#{day.to_s} 当日工作地#{@location}，因当地享受高寒补贴, 当天寒冷补贴为: 0 元")
          else
            if vacation_days_hash[day].present? && vacation_days_hash[day].to_f < 1
              if @city_config[@location].present? && @city_config[@location][@cold_subsidy_type].present?
                per_day_amout = (1 - vacation_days_hash[day].to_f) * @amount_config[@cold_subsidy_type][@city_config[@location][@cold_subsidy_type]]
                @cold_subsidy_amount = @cold_subsidy_amount + per_day_amout
                calc_step.push_step("#{day.to_s} 当日请假#{vacation_days_hash[day]}天, 当天寒冷补贴为 #{per_day_amout} 元")
              else
                calc_step.push_step("#{day.to_s} 当日工作地#{@location}，因工作地不享受寒冷补贴，当天寒冷补贴为 0 元")
              end
            else
              calc_step.push_step("#{day.to_s} 当日工作地#{@location}，但是处于离岗培训或者请假1天, 当天寒冷补贴为: 0 元")
            end
          end
          next
        end

        if @city_config[@location].present? && @city_config[@location][@cold_subsidy_type].present?
          #正常工作日
          per_day_amout = @amount_config[@cold_subsidy_type][@city_config[@location][@cold_subsidy_type]]
          @cold_subsidy_amount = @cold_subsidy_amount + per_day_amout
          calc_step.push_step("#{day.to_s} 当日工作地#{@location}, 正常出勤, 当天寒冷补贴为 #{per_day_amout} 元")
        else
          calc_step.push_step("#{day.to_s} 当日工作地#{@location}，因工作地不享受寒冷补贴，当天寒冷补贴为 0 元")
        end
      end

      evection_days = employee.evection_days(month).to_f
      if evection_days > 0
        remove_amount = @amount_config[@cold_subsidy_type][@city_config[@location][@cold_subsidy_type]] * evection_days
        @cold_subsidy_amount = @cold_subsidy_amount - remove_amount
        calc_step.push_step("员工当月出差#{evection_days}天, 扣减寒冷补贴#{remove_amount}元")
      end
      calc_step.push_step("员工当月寒冷补贴总计#{@cold_subsidy_amount}元")
    when "B"
      calc_step.push_step("员工寒冷补贴类型的为:乙类员工, 以下为计算过程:")

      vacation_days, vacation_days_hash   = calc_vacation_days(employee, month)
      location_days_hash, study_days_list = calc_cold_subsidy_days(employee, @location, month)

      study_vacation_days_list = study_days_list | vacation_days_hash.keys

      location_vacation_days = location_days_hash.keys & study_vacation_days_list

      @off_working_days = 0

      (@start_date..@end_date).to_a.each do |day|
        if location_vacation_days.include?(day) #派驻中，但是请假或者离岗培训
          if vacation_days_hash[day].present? && vacation_days_hash[day].to_f < 1
            if has_highland_cold_subsidy?(@send_location, month)
              @off_working_days += 1
              calc_step.push_step("#{day.to_s} 驻派 #{@send_location}, 因驻地享受高寒补贴, 计入不发放寒冷补贴天数")
            else
              if @city_config[@send_location].present? && @city_config[@send_location][@cold_subsidy_type]
                @off_working_days += vacation_days_hash[day]
                calc_step.push_step("#{day.to_s} 派驻 #{@send_location}，请假或旷工#{vacation_days_hash[day]}天, #{vacation_days_hash[day]}计入不发放寒冷补贴天数")
              else
                @off_working_days += 1
                calc_step.push_step("#{day.to_s} 派驻 #{@send_location}，请假或旷工#{vacation_days_hash[day]}天, 因驻地不享受寒冷补贴，计入不发放寒冷补贴天数")
              end
            end
          else
            @off_working_days += 1
            calc_step.push_step("#{day.to_s} 派驻 #{@send_location}，但是处于请假或离岗培训, 计入不发放寒冷补贴天数")
          end
          next
        end

        if location_days_hash.keys.include?(day) #派驻中，正常上班
          @send_location = location_days_hash[day]
          if has_highland_cold_subsidy?(@send_location, month)
            @off_working_days += 1
            calc_step.push_step("#{day.to_s} 驻派 #{@send_location}, 因驻地享受高寒补贴, 计入不发放寒冷补贴天数")
          else
            if @city_config[@send_location].present? && @city_config[@send_location][@cold_subsidy_type]
              #正常计发寒冷补贴
              calc_step.push_step("#{day.to_s} 派驻 #{@send_location}, 发放寒冷补贴")
            else
              @off_working_days += 1
              calc_step.push_step("#{day.to_s} 派驻 #{@send_location}，因驻地不享受寒冷补贴, 计入不发放寒冷补贴天数")
            end
          end
          next
        end

        if study_vacation_days_list.include?(day) #请休假，离岗培训
          if has_highland_cold_subsidy?(@location, month)
            calc_step.push_step("#{day.to_s} 工作地#{@location}，因当地享受高寒补贴, 计入不发放寒冷补贴天数")
          else
            if vacation_days_hash[day].present? && vacation_days_hash[day].to_f < 1
              if @city_config[@location].present? && @city_config[@location][@cold_subsidy_type].present?
                @off_working_days += vacation_days_hash[day]
                calc_step.push_step("#{day.to_s} 请假或旷工#{vacation_days_hash[day]}天, #{vacation_days_hash[day]}天计入不发放寒冷补贴天数")
              else
                @off_working_days += 1
                calc_step.push_step("#{day.to_s} 工作地#{@location}，因工作地不享受寒冷补贴，计入不发放寒冷补贴天数")
              end
            else
              @off_working_days += 1
              calc_step.push_step("#{day.to_s} 工作地#{@location}，但是处于离岗培训或者请假1天, 计入不发放寒冷补贴天数")
            end
          end
          next
        end

        if @city_config[@location].present? && @city_config[@location][@cold_subsidy_type].present?
          #正常计发寒冷补贴
          calc_step.push_step("#{day.to_s} 工作地为#{@location}, 发放寒冷补贴")
        else
          @off_working_days += 1
          calc_step.push_step("#{day.to_s} 工作地为#{@location}, 因工作地不享受寒冷补贴，计入不发放寒冷补贴天数")
        end
      end

      if (@off_working_days + employee.evection_days(month)) < @end_date.day
        if (@off_working_days + employee.evection_days(month)) <= 15
          @cold_subsidy_amount = @amount_config[@cold_subsidy_type]
          calc_step.push_step("当月不发放寒冷补贴天数#{@off_working_days}天,出差#{employee.evection_days(month)}天,未超过15个自然日,寒冷补贴全额发放,补贴:#{@cold_subsidy_amount} 元")
        else
          @cold_subsidy_amount = @amount_config[@cold_subsidy_type] * 0.5
          calc_step.push_step("当月不发放寒冷补贴天数#{@off_working_days}天,出差#{employee.evection_days(month)}天,超过15个自然日,寒冷补贴减半发放,补贴为:#{@cold_subsidy_amount} 元")
        end
      else
        @cold_subsidy_amount = 0
        calc_step.push_step("当月不发放寒冷补贴天数#{@off_working_days}天,出差#{employee.evection_days(month)}天,等于当月天数,寒冷补贴不予发放,补贴为:0 元")
      end
    else
      calc_step.push_step("员工不符合寒冷补贴发放条件,员工寒冷补贴的为: 0")
    end

    @cold_subsidy_amount
  end

  def self.has_highland_cold_subsidy?(city, month)
    city_list = Salary.where(category: 'land_subsidy').first.form_data['high_cold']['cities']
    if [11,12,1,2,3].include?("#{month}-01".to_date.month) && city_list.include?(city)
      true
    else
      false
    end
  end

  # 计算高温补贴
  def self.calc_temperature(employee, month, calc_step)
    # 高温补贴的设置
    @amount = 0
    @standard = employee.positions.map(&:temperature_amount).max

    calc_step.push_step("岗位对应的最高高温补贴设置是 #{@standard}")

    if employee.salary_person_setup.temp_allowance.present?
      # 个人设置的优先级最高
      @standard = employee.salary_person_setup.temp_allowance.to_i
      calc_step.push_step("员工薪酬个人设置有单独的高温补贴设置，设置为 #{@standard}")
    end

    @compute_month = Date.parse(month + '-01').month

    if employee.is_fly_channel? || employee.is_air_service_channel?
      calc_step.push_step('处于飞行通道')

      # 判断是否没有飞行，没有飞就不发
      if employee.is_unfly?(month)
        calc_step.push_step('当月没有飞行，补贴金额为 0')
        @amount = 0
      elsif @compute_month >= 6 && @compute_month <= 9
        calc_step.push_step("按照 6-9 月时间补贴 300 标准执行")
        @amount = 300

        if employee.salary_person_setup.temp_allowance.to_i > 300
          @amount = employee.salary_person_setup.temp_allowance.to_i
          calc_step.push_step("员工薪酬个人设置有单独的高温补贴设置，设置为 #{@amount}")
        end
      else
        calc_step.push_step("非 6-9 月时间，补贴为 0")
        @amount = 0
      end

      return @amount
    end

    # 员工属地
    @location = employee.location
    calc_step.push_step("设置的属地是 #{@location}")

    # 是否有派驻派驻属累加天数
    @send_days, @total_send_dates = send_location_days(employee, @location, month, calc_step)
    @total_send_days = @total_send_dates.size
    calc_step.push_step("当月派驻累加有效天数是 #{@send_days}")

    if @total_send_dates.size >= 15
      if @send_days >= 15
        calc_step.push_step("派驻累计天数已经超过 15 天，扣除考勤后 #{@send_days} 天，实行全月高温补贴 #{@standard}")
        return @amount = @standard
      elsif @send_days > 0
        calc_step.push_step("派驻累计天数已经超过 15 天，扣除考勤后 #{@send_days} 天，实行半月高温补贴 #{@standard * 0.5}")
        @amount = @standard * 0.5
      else
        calc_step.push_step("派驻累计天数已经超过 15 天，扣除考勤后 #{@send_days} 天，不发放高温补贴")
      end
    elsif @total_send_dates.size > 0
      prev_month = Date.parse(month + '-01').prev_month.strftime("%Y-%m")
      prev_send_days, prev_total_send_dates = send_location_days(employee, @location, prev_month, calc_step)
      if @total_send_dates.size + prev_total_send_dates.size >= 15
        if @send_days + prev_total_send_dates.size >= 15
          calc_step.push_step("本月和上月派驻合计天数已经超过 15 天，扣除本月考勤后 #{@send_days + prev_total_send_dates.size} 天，实行全月高温补贴 #{@standard}")
          return @amount = @standard
        elsif @send_days + prev_total_send_dates.size > 0
          calc_step.push_step("本月和上月派驻合计天数已经超过 15 天，扣除本月考勤后 #{@send_days + prev_total_send_dates.size} 天，实行半月高温补贴 #{@standard * 0.5}")
          @amount = @standard * 0.5
        else
          calc_step.push_step("本月和上月派驻合计天数已经超过 15 天，扣除本月考勤后 #{@send_days + prev_total_send_dates.size} 天，不发放高温补贴")
        end
      end
    end

    # 员工本来的属地天数
    @location_days = Date.parse(month + "-01").end_of_month.day - @total_send_days
    @vacation_dates = employee.get_vacation_dates(month)
    setting = load_setting_city()

    if setting[@location].present?
      calc_step.push_step("当前月份是 #{@compute_month}")
      calc_step.push_step("属地 #{@location} 对应的高温补贴月份是 #{setting[@location]['start_month']}-#{setting[@location]['end_month']}")

      start_date = Date.parse(month + '-01')
      end_date = Date.parse(month + '-01').end_of_month

      (start_date..end_date).to_a.each do |d|
        if !@total_send_dates.include?(d)
          # 首先不是驻站日期
          if @vacation_dates[d].present?
            # 如果请假就扣除相应的天数
            @location_days -= @vacation_dates[d].to_f
          end

          calc_step.push_step("原属地 #{d} 请假 #{@vacation_dates[d].to_f} 天")
        else
          # calc_step.push_step("驻站地 #{d} 请假 #{@vacation_dates[d].to_f} 天")
        end
      end

      if @compute_month >= setting[@location]['start_month'].to_i && @compute_month <= setting[@location]['end_month'].to_i
        if @location_days >= 15
          calc_step.push_step("员工属地本身满足高温补贴条件, 且超过 15 天(#{@location_days}), 实行全月高温补贴 #{@standard}")
          return @amount = @standard
        elsif @location_days > 0
          # 没有超过 15 天的情况需要考虑请假，而且是考虑在本属地的请假情况，所以先要扣除所有驻站的日期(不仅仅是有高温补贴的)
          @amount += @standard * 0.5
          calc_step.push_step("员工属地本身满足高温补贴条件，属地当月上班未超过 15 天(#{@location_days})，需要参考请假情况")
        end
      else
        calc_step.push_step("员工属地 #{@location} 有高温补贴设置，但是月份条件不满足")
        @location_days = 0
      end
    else
      calc_step.push_step("员工属地 #{@location} 没有高温补贴设置")
      @location_days = 0
    end

    calc_step.push_step("员工属地符合高温补贴条件的当月上班天数是 #{@location_days} 天，驻站符合高温补贴条件天数 #{@send_days}")

    # if (@location_days + @send_days) >= 15
    #   calc_step.push_step("驻站符合高温补贴天数和属地符合高温补贴天数累计超过 15 天，全发 #{@amount}")
    #   return @amount
    # elsif (@location_days + @send_days) > 0
    #   calc_step.push_step("驻站符合高温补贴天数和属地符合高温补贴天数累计大于 0 但是未超过 15 天，发一半 #{@amount * 0.5}")
    #   return @amount * 0.5
    # end
    @amount = @standard if @amount > @standard
    calc_step.push_step("没有派驻地或者所有派驻地不符合高温补贴条件，并且员工属地也不满足高温补贴条件或者当月没有在本属地上班，金额为 0") if @amount == 0
    return @amount
  end

  def self.calc_vacation_days(employee, month)
    vacation_days_hash = employee.get_vacation_dates(month)
    vacation_days = 0
    vacation_days_hash.each do |date, value|
      vacation_days = vacation_days + value.to_f
    end
    return vacation_days, vacation_days_hash
  end

  def self.calc_cold_subsidy_days(employee, origin_location, month)
    #计算员工非原地址驻派驻地点，派驻日期地点Hash
    #计算员工离岗培训的日期Array
    location_days_hash = {}
    study_days_list    = []

    month      = Date.parse(month + '-01')
    start_date = month.beginning_of_month
    end_date   = month.end_of_month

    SpecialState.where(employee: employee, special_category: '派驻').order(:special_date_from).each do |state|
      next if state.special_location == origin_location
      array = nil
      if state.special_date_to.blank?
        array = state.special_date_from..end_date
      else
        array = state.special_date_from..state.special_date_to
      end
      array.to_a.each do |day|
        if day >= start_date && day <= end_date
          location_days_hash[day] = state.special_location
        end
      end
    end

    SpecialState.where(employee: employee, special_category: '离岗培训').order(:special_date_from).each do |state|
      array = nil
      if state.special_date_to.blank?
        array = state.special_date_from..end_date
      else
        array = state.special_date_from..state.special_date_to
      end

      array.to_a.each do |day|
        if day >= start_date && day <= end_date
          study_days_list << day
        end
      end
    end

    return location_days_hash, study_days_list
  end

  # 当月的派驻地点，派回有效高温补贴派驻地累计天数
  def self.send_location_days(employee, origin_location, month, calc_step)
    setting         = load_setting_city()
    days_list       = []
    total_days_list = []

    month_value = Date.parse(month + '-01').month
    start_date  = Date.parse(month + '-01')
    end_date    = Date.parse(month + '-01').end_of_month

    # 当月请假的日期集合
    vacation_dates = employee.get_vacation_dates(month)
    substract_days = 0

    SpecialState.where(employee_id: employee.id, special_category: '派驻').each do |state|
      if state.special_location == origin_location
        calc_step.push_step("派驻地 #{state.special_location} 和员工属地 #{origin_location} 相同")
        next
      end

      setting_city = setting[state.special_location]

      if !setting_city
        calc_step.push_step("派驻地 #{state.special_location} 无高温补贴设置")
        next
      else
        calc_step.push_step("驻地 #{state.special_location} 对应的高温补贴月份是 #{setting_city['start_month']}-#{setting_city['end_month']}")
      end

      # 改派驻地有高温补贴设置
      if month_value >= setting_city['start_month'].to_i && month_value <= setting_city['end_month'].to_i
        # 设置的月份
        array = nil
        if state.special_date_to.blank?
          array = state.special_date_from..end_date
        else
          array = state.special_date_from..state.special_date_to
        end
        array.to_a.each do |d|
          if d >= start_date && d <= end_date
            # 统计所有的驻站天数，无论符合不符合高温补贴条件
            total_days_list << d

            days_list << d unless vacation_dates[d].present?
            # 考虑请假 0.5 天的情况
            substract_days += 0.5 if vacation_dates[d].to_f == 0.5
            calc_step.push_step("日期 #{d}, #{state.special_location} 符合高温补贴条件，请假天数 #{vacation_dates[d].to_f}")
          end
        end
      else
        calc_step.push_step("当前月 #{month} 不符合派驻地 #{state.special_location} 月份设置")
      end
    end

    return [days_list.uniq.size + substract_days, total_days_list]
  end

  def self.load_setting_city()
    setting = {}

    Salary.where(category: 'temp').first.form_data['city_list'].each do |item|
      item['cities'].each do |city|
        setting[city] = {"start_month"=>item['start_month'], "end_month"=>item['end_month']}
      end
    end

    setting
  end

  def self.load_cold_subsidy_config(month)
    setting = {}
    Salary.where(category: 'cold_subsidy').first.form_data['city_config'].each do |item|
      setting[item["name"]] = {
        "A" => item["M_A_#{month}"].present? ? item["M_A_#{month}"] : '',
        "B" => item["M_B_#{month}"] == "true" ? true : false
      }
    end
    setting
  end

  def self.load_cold_subsidy_amount_config
    Salary.where(category: 'cold_subsidy').first.form_data['personnel_amount_config']
  end
end

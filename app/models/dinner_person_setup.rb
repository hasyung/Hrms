class DinnerPersonSetup < ActiveRecord::Base
  serialize :form_data, Hash
  belongs_to :employee

  before_save do |setup|
    # 非个人饭卡，员工编号w开头
    exists = Employee.find_by(id: setup.employee_id).present?

    if exists
      setup.is_external = true
      setup.employee_no = 'g' + setup.employee_no
    end

    # 早中晚次数之和
    setup.card_number = setup.total_number
  end

  def uniq_key
    # 餐费区域和饭卡编号可以唯一确定1条餐费设置记录
    self.area + self.employee_no
  end

  def copy_to_form_data(persisted = false)
    [:card_amount, :breakfast_number, :lunch_number, :dinner_number, :working_fee].each do |field|
      self.form_data[field] = self.send(field)
    end
    self.form_data[:card_number] = self.total_number

    self.save if persisted
  end

  def copy_from_form_data(type)
    if type == "工作餐"
      self.card_amount = self.form_data[:card_amount]
      self.breakfast_number = self.form_data[:breakfast_number]
      self.lunch_number = self.form_data[:lunch_number]
      self.dinner_number = self.form_data[:dinner_number]
      self.card_number = self.total_number
    elsif type == "误餐费"
      self.working_fee = self.form_data[:working_fee]
    end
  end

  # 计算变动文件的数据
  def calc_change
    # 夜宵暂时为0
    return {
      Bzje: self.card_amount,
      Bzcs_Zc: self.breakfast_number,
      Bzcs_Zw: self.lunch_number,
      Bzcs_Ws: self.dinner_number,
      Bzcs_Yx: 0
    } unless self.persisted?

    {
      Bzje: self.card_amount.to_f - self.card_amount_was.to_f.to_f,
      Bzcs_Zc: self.breakfast_number.to_i - self.breakfast_number_was.to_i,
      Bzcs_Zw: self.lunch_number.to_i - self.lunch_number_was.to_i,
      Bzcs_Ws: self.dinner_number.to_i - self.dinner_number_was.to_i,
      Bzcs_Yx: 0
    }
  end

  def check_and_fix_setting(send_month, type)
    # 如果有变动日期则使用变动时间对应的月份
    # 否则使用最后的更新时间对应的月份(可能是创建时间，也可能不是，因为可能改了班制等造成修改)
    @changed_month = self.change_date.month
    @changed_month = self.updated_at.month unless @changed_month

    if self.is_suspend
      # 如果是暂停发放，而且变动日期对应的月份和发放月份相同的则满算(正发倒扣)
      if Date.parse(send_month + "-01").month == @changed_month
        self.copy_from_form_data(type)
        return
      end
    end

    if type == "工作餐"
      # 8 月份添加的记录 9 月份的工作餐已充值，9 月份的时候充值 10 月份的时候满算
      # 参数month 是 10 月份
      if Date.parse(send_month + "-01").prev_month.prev_month.month != @changed_month
        self.copy_from_form_data(type)
      end
    elsif type == "误餐费"
      # 8 月份添加的记录 9 月份的时候才会算 8 月份的误餐费，8 月份没有满月，10 月份的时候满算 9 月份的
      # 参数 month 是 9 月份的
      if Date.parse(send_month + "-01").prev_month.month != @changed_month
        self.copy_from_form_data(type)
      end
    end
  end

  # 变动新进，只按照规则修改设置数据
  def change_newbie
    self.create_newbie
  end

  # 直接添加记录的逻辑和变动-新进员工的逻辑是不同的
  def create_newbie
    if self.is_mealcard_area?
      # 饭卡
      self.half_meal_card() if self.change_date.day >= 15
    else
      # 含当天，距离月底天数(含当天)/当月天数*月标准
      self.working_fee = self.ending_month_days / self.month_working_fee
    end
  end

  # 离职
  def change_leave
    if self.is_mealcard_area?
      # 饭卡
      if self.change_date.day < 15
        self.half_meal_card()
      else
        # 不扣减
        self.card_amount = self.month_working_days / self.total_days * self.card_amount
      end
    elsif self.is_special?
      # 重庆食堂/昆明食堂
      self.working_fee -= free_days / self.month_working_fee
    else
      # 现金
      self.working_fee = self.month_working_days / self.month_working_fee
    end
  end

  # 飞行员下队
  # 参数 new_record 是检测员工是否有目标区域的设置记录，调用者载入或者新建
  def change_flyer_leave_student(new_record)
    if new_record.change_date.day < 15
      # 原饭卡扣减半月金额/次数
      self.half_meal_card()

      if ["机关食堂", "空勤食堂"].include?(self.area) && new_record.area == '北头食堂'
        # 机关食堂 -> 北头食堂，新饭卡发放空勤班全月金额/次数
      elsif ["机关食堂", "空勤食堂"].include?(self.area) && !new_record.is_mealcard_area?
        # 机关食堂 -> 现金，新饭卡发放距离月底天数(含当天)/当月天数*月金额
        new_record.working_fee = new_record.ending_month_days / new_record.month_working_fee
      end
    else
      if ["机关食堂", "空勤食堂"].include?(self.area) && new_record.area == '北头食堂'
        # 机关食堂 -> 北头食堂，原饭卡不做扣减，新饭卡发放空勤班半月金额/次数
      elsif ["机关食堂", "空勤食堂"].include?(self.area) && !new_record.is_mealcard_area?
        # 机关食堂 -> 现金，原饭卡不做扣减，新饭卡发放距离月底天数(含当天)/当月天数*月金额
        new_record.working_fee = new_record.ending_month_days / new_record.month_working_fee
      end
    end
  end

  # 工作地点调整
  # 参数 new_record 是检测员工是否有目标区域的设置记录，调用者载入或者新建
  def change_location(new_record)
    if new_record.change_date.day < 15
      if ["机关食堂", "空勤食堂"].include?(self.area) && new_record.area == '北头食堂'
        # 机关食堂 -> 北头食堂，原饭卡扣减半月金额/次数
        self.half_meal_card()
      elsif self.is_mealcard_area? && !new_record.is_mealcard_area?
        # 饭卡 -> 现金，原饭卡扣减半月金额/次数
        self.half_meal_card()
        new_record.working_fee = new_record.ending_month_days / new_record.month_working_fee
      elsif !self.is_mealcard_area? && new_record.is_mealcard_area?
        # 现金 -> 饭卡
        self.working_fee -= self.ending_month_days / self.month_working_fee
      elsif !self.is_mealcard_area? && !new_record.is_mealcard_area?
        # 现金 -> 现金
        self.working_fee -= self.ending_month_days / self.month_working_fee
        new_record.working_fee = new_record.ending_month_days / new_record.month_working_fee
      end
    else
      if ["机关食堂", "空勤食堂"].include?(self.area) && new_record.area == '北头食堂'
        new_record.half_meal_card()
      elsif self.is_mealcard_area? && !new_record.is_mealcard_area?
        new_record.working_fee = new_record.ending_month_days / new_record.month_working_fee
      elsif !self.is_mealcard_area? && new_record.is_mealcard_area?
        self.working_fee -= self.ending_month_days / self.month_working_fee
        new_record.half_meal_card()
      elsif !self.is_mealcard_area? && !new_record.is_mealcard_area?
        self.working_fee -= self.ending_month_days / self.month_working_fee
        new_record.working_fee = new_record.ending_month_days / new_record.month_working_fee
      end
    end
  end

  # 班制调整
  def change_shifts_type
    if self.change_date.day < 15
      if self.card_amount_was.to_f < self.card_amount
        # 原班制金额或次数＜新班制金额或次数，补发（新班制金额或次数-原班制金额或次数）
        self.card_amount += self.card_amount - self.card_amount_was.to_f
      else
        # 原班制金额或次数>新班制金额或次数，扣减（原班制金额或次数-新班制金额或次数) / 2
        self.card_amount -= DinnerPersonSetup.half_of(self.card_amount_was.to_f - self.card_amount)
      end

      if self.breakfast_number_was < self.breakfast_number
        self.breakfast_number += self.breakfast_number - self.breakfast_number_was
      else
        self.breakfast_number -= DinnerPersonSetup.half_of(self.breakfast_number_was - self.breakfast_number)
      end

      if self.lunch_number_was < self.lunch_number
        self.lunch_number += self.lunch_number - self.lunch_number_was
      else
        self.lunch_number -= DinnerPersonSetup.half_of(self.lunch_number_was - self.lunch_number)
      end

      if self.dinner_number_was < self.dinner_number
        self.dinner_number += self.dinner_number - self.dinner_number_was
      else
        self.dinner_number -= DinnerPersonSetup.half_of(self.dinner_number_was - self.dinner_number)
      end
    else
      if self.card_amount_was.to_f < self.card_amount
        # 原班制金额或次数＜新班制金额或次数，补发（新班制金额或次数-原班制金额或次数）/ 2.0
        # 原班制金额或次数>新班制金额或次数，不处理
        self.card_amount ||= 0
        self.card_amount += DinnerPersonSetup.half_of(self.card_amount - self.card_amount_was.to_f)
      end

      if self.breakfast_number_was < self.breakfast_number
        # 原班制金额或次数>新班制金额或次数，不处理
        self.breakfast_number += DinnerPersonSetup.half_of(self.breakfast_number - self.breakfast_number_was)
      end

      if self.lunch_number_was < self.lunch_number
        # 原班制金额或次数>新班制金额或次数，不处理
        self.lunch_number += DinnerPersonSetup.half_of(self.lunch_number - self.lunch_number_was)
      end

      if self.dinner_number_was < self.dinner_number
        # 原班制金额或次数>新班制金额或次数，不处理
        self.dinner_number += DinnerPersonSetup.half_of(self.dinner_number - self.dinner_number_was)
      end
    end
  end

  # 个人设置现金区域被修改，现金->现金，参考工作地点变动规则
  def change_cash_location
    @config = DinnerPersonSetup.area_config()[self.area]

    @old_working_fee = self.total_days * self.working_fee_was.to_f
    @new_working_fee = self.month_working_fee

    # 现金 -> 现金
    @fee = self.working_fee_was.to_f

    if self.change_date.day < 15
      @fee -= self.ending_month_days / self.total_days * @old_working_fee
      @fee += self.ending_month_days / self.total_days * @new_working_fee
    else
      @fee -= self.ending_month_days / self.total_days * @old_working_fee
      @fee += self.ending_month_days / self.total_days * @new_working_fee
    end

    self.working_fee = @fee
  end

  # 休假
  def process_normal(month, calc_step, category, type)
    @config = DinnerPersonSetup.area_config

    # 11 月份看 9 月份的考勤
    look_month = Date.parse(month + "-01").prev_month.prev_month.strftime("%Y-%m")
    calc_total_days = Date.parse(month + "-01").end_of_month.day
    return unless self.employee.present?

    @last_type_days = employee.get_attendance_type_days(category, look_month)
    @last_2_type_days = employee.get_attendance_type_days(category, look_month, 2)
    type_name = {'vacation' => '休假', 'leave_position' => '离岗培训', 'business_trip' => '出差'}[type]

    calc_step.push_step("#{look_month} #{type_name}天数 #{@last_type_days}，#{look_month}和上月#{type_name}天数 #{@last_2_type_days}")

    if @last_type_days == 0 && @last_2_type_days == 0
      calc_step.push_step("未出现休假/离岗培训/出差")
      return
    end

    if self.is_mealcard_area?
      if self.employee.full_month_vacation?(look_month, 2)
        self.card_amount = 0
        calc_step.push_step("上月全月#{type_name}，不充值金额，仅充值次数")
      elsif @last_type_days > 15 || @last_2_type_days > 15
        self.card_amount = DinnerPersonSetup.half_of(self.card_amount)
        calc_step.push_step("上月#{type_name} > 15 天(自然日) 或者 上两月#{type_name} > 15 天(自然日)，充值一半金额，不扣减次数，卡金额 #{self.card_amount}")
      end
    else
      if type == "误餐费"
        self.working_fee = self.month_working_fee(month)

        # 现金区域和重庆昆明/昆明食堂的规则是一样的
        if self.employee.full_month_vacation?(look_month, 2)
          self.working_fee = 0
          calc_step.push_step("上月全月#{type_name}不充值金额，本月不充值金额，工作餐为 0")
        elsif @last_type_days > 15
          self.working_fee = self.month_working_fee(month) - (self.month_working_fee(month) * @last_type_days / calc_total_days)
          calc_step.push_step("上月#{type_name} > 15 天(自然日)，充值扣减天数/当月天数 * 月标准，工作餐 #{self.working_fee}")
        end

        # 如果有欠费就要扣减
        self.fill_deficit if self.deficit_amount > 0 && self.working_fee > 0
      end
    end
  end

  # 执行抵扣金额
  def fill_deficit
    if self.working_fee > self.deficit_amount
      self.working_fee -= self.deficit_amount
      self.deficit_amount = 0
    else
      self.working_fee = 0
      self.deficit_amount -= self.working_fee
    end
  end

  # 驻站
  def process_landing(month, calc_step, type)
    # 驻站规则:
    # 0. 长水机场的驻地其实是昆明，值几天班(导入值班数据)就补贴几天(按照长水机场设置的标准)，这种情况他们的餐费设置不会直接设置成长水机场，依然是员工本来的驻地
    # 1. 非空勤和飞行通道的地面人员驻站，西安驻站不包含机务通道(是机务通道的有驻站不补贴，原驻地照扣，也就是驻派西安的机务通道的员工照扣不发)
    # 2. 西安驻站和哈尔滨驻站的标准是独立的，哈尔滨驻站不用排除机务
    # 3. 空勤和飞行通道的员工在重庆和昆明驻站是独立标准，其他驻站地点不补贴
    # 4. 出现西安驻站和哈尔滨驻站的情况，如果超过 15 天，则开始按天扣减原驻地，否则原驻地不扣减
    look_month = Date.parse(month + "-01").prev_month.prev_month.strftime("%Y-%m")
    calc_total_days = Date.parse(month + "-01").end_of_month.day
    return unless self.employee.present?

    # 区域配置
    @area_config = DinnerPersonSetup.area_config
    @total_special_days = 0

    start_date = Date.parse(look_month + "-01").beginning_of_month
    end_date = Date.parse(look_month + "-01").end_of_month

    @states = SpecialState.where(employee_id: self.employee.id)
    @state_dates = []
    @states.each do |state|
      @state_dates << (state.special_date_from..state.special_date_to).to_a
    end

    @state_dates.flatten!
    @state_dates.uniq!

    (start_date..end_date).to_a.each do |date|
      @total_special_days += 1 if @state_dates.include?(date)
    end

    unless @total_special_days > 0
      calc_step.push_step("#{look_month} 派驻天数为 0")
      return
    end

    @states.each do |state|
      @special_days = 0

      (start_date..end_date).to_a.each do |date|
        @special_days += 1 if @state_dates.include?(date)
      end

      if type == "误餐费"
        send_location = state.special_location
        calc_step.push_step("员工属地 #{self.employee.location}，派驻地 #{send_location}")
        next unless self.employee.location != send_location

        send_location += "派驻" if ["西安", "哈尔滨"].include?(send_location)
        @config = @area_config[send_location]

        if @config.blank?
          calc_step.push_step("#{send_location} 没有餐费设置")
        else
          if self.employee.is_fly_channel? || self.employee.is_air_service_channel?
            # 空勤和飞行只有重庆和昆明有补贴 50元/天
            if ["重庆", "昆明"].include?(state.special_location)
              @fee = 50 * @special_days
              calc_step.push_step("飞行和空勤通道的重庆和昆明驻站标准为 50元/天")
            else
              @fee = 0
              calc_step.push_step("飞行和空勤通道的驻站只有重庆和昆明有补贴")
            end
          else
            # 如果是机务驻站西安不补贴
            if self.employee.channel.name == '机务' && state.special_location == '西安'
              calc_step.push_step('机务通道驻站西安不补贴')
            else
              # 按天计算
              @base_amount = @config[:amount].to_f
              calc_step.push_step("驻地标准 #{@base_amount}/天")

              @fee = @base_amount * @special_days
              calc_step.push_step("发放驻站天数/当月天数 * 驻站地月金额，工作餐驻地补贴 #{@fee}")
            end
          end

          calc_step.push_step("原属地工作餐设置 #{self.working_fee}")

          if !self.is_mealcard_area? && @total_special_days > 15
            # 原属地是现金区域并且 >15 天后开始扣减(现金 -> 现金)
            self.working_fee = self.month_working_fee - self.month_working_fee * @special_days / calc_total_days
            calc_step.push("原属地扣减后金额 #{self.working_fee}")
          end

          self.working_fee += @fee
          calc_step.push_step("工作餐总和 #{self.working_fee}")
        end

        # 如果有欠费就要扣减
        self.fill_deficit() if self.deficit_amount > 0 && self.working_fee > 0
      end

      if self.is_mealcard_area? && DinnerPersonSetup.is_cash_area?(send_location)
        # 饭卡 -> 现金
        if @total_special_days <= 15
          calc_step.push_step("派驻天数 <= 15 天，不做扣减")
        else
          calc_step.push_step("派驻天数 > 15 天")
          calc_step.push_step("扣减半月金额")
          self.card_amount = DinnerPersonSetup.half_of(self.card_amount)
          calc_step.push_step("卡金额 #{self.card_amount}")
        end
      end
    end
  end

  def generate_change_xls(mode, file_path, change_data)
    operate_kind = {"新增" => 1, "离职" => 2, "修改资料" => 3}
    @book = Spreadsheet::Workbook.new
    @sheet = @book.create_worksheet(name: "#{@data_month}消费流水")

    %w(OperateKind WorkNo Name KindName01 KindName02 DepartName01 DepartName02 DepartName03 DepartName04 Bzje Bzcs_Zc Bzcs_Zw Bzcs_Ws Bzcs_Yx BzcsStart BzcsEnd).each_with_index do |name, column|
      @sheet[0, column] = name
    end

    @sheet[1, 0] = operate_kind[mode]
    @sheet[1, 1] = self.employee_no.downcase
    @sheet[1, 2] = self.employee_name
    @sheet[1, 3] = "股份人员"
    @sheet[1, 4] = area.gsub("食堂", "")

    @full_name = self.employee.department.try(:full_name).to_s.split("-")
    @sheet[1, 5] = "四川航空"
    @sheet[1, 6] = @full_name[0]
    @sheet[1, 7] = @full_name[1]
    @sheet[1, 8] = @full_name[2]

    @sheet[1, 9] = change_data[:Bzje].to_i
    @sheet[1, 10] = change_data[:Bzcs_Zc].to_i
    @sheet[1, 11] = change_data[:Bzcs_Zw].to_i
    @sheet[1, 12] = change_data[:Bzcs_Ws].to_i
    @sheet[1, 13] = change_data[:Bzcs_Yx].to_i

    @sheet[1, 14] = Time.new.beginning_of_month.strftime("%Y-%m-%d")
    @sheet[1, 15] = Time.new.end_of_month.strftime("%Y-%m-%d")

    @book.write file_path
  end

  def total_number
    self.breakfast_number.to_i + self.lunch_number.to_i + self.dinner_number.to_i
  end

  # 是否是饭卡区域
  def is_mealcard_area?
    # 昆明食堂/重庆食堂是现金区域，但是导出表不同
    ["机关食堂", "空勤食堂", "北头食堂",].include? (self.area)
  end

  def self.is_cash_area?(location)
    !["机关食堂", "空勤食堂", "北头食堂",].include? (location)
  end

  def self.is_card_area?(location)
    !DinnerPersonSetup.is_cash_area?(location)
  end

  def is_special?
    ["昆明食堂", "重庆食堂"].include?(self.area)
  end

  def self.area_config
    @form_data = Welfare.find_by(category: 'dinners').form_data
    hash = {}

    if @form_data.present?
      @form_data[0]['chengdu_head_office'].each do |dict|
        hash[dict['areas'] + "@" + dict["shifts_type"]] = dict
      end

      @form_data[1]['chengdu_north_part'].each do |dict|
        hash[dict['areas'] + "@" + dict["shifts_type"]] = dict
      end

      @form_data[2]['others'].each do |dict|
        dict['cities'].each do |city|
          dict.delete("cities")
          hash[city] = dict
        end
      end
    end

    hash
  end

  # 数值清零
  def clear
    self.card_amount = self.working_fee = 0
    self.breakfast_number = self.lunch_number = self.dinner_number = 0

    self.form_data[:card_amount] = self.form_data[:working_fee] = 0
    self.form_data[:breakfast_number] = self.form_data[:lunch_number] = self.form_data[:dinner_number] = self.form_data[:card_number] = 0

    self.save
  end

  # 饭卡的数值减半
  def half_meal_card
    self.card_amount = DinnerPersonSetup.half_of(self.card_amount)
    self.breakfast_number = DinnerPersonSetup.half_of(self.breakfast_number)
    self.lunch_number = DinnerPersonSetup.half_of(self.lunch_number)
    self.dinner_number = DinnerPersonSetup.half_of(self.dinner_number)
  end

  # 减半，如果是奇数还要加1个
  def self.half_of(value)
    value = value.to_i
    x = value / 2.0
    return x + 1 if value.odd?
    x
  end

  # 某月的误餐费总额
  def month_working_fee(month = nil)
    if month.present?
      # 如果指定了月份调用，则是指定月份对应的天数(计算月份)
      return self.working_fee.to_f * Date.parse(month + "-01").end_of_month.day
    end

    # 否则是变动日期对应的天数
    self.working_fee.to_f * self.total_days
  end

  # 变动当月距离月底的天数
  def ending_month_days
    self.change_date.end_of_month.day - self.change_date.day + 1
  end

  # 变动当月共多少天
  def total_days
    self.change_date.end_of_month.day
  end

  # 变动当月的工作日是多少天
  def month_working_days
    total_days = self.change_date.end_of_month.day
    start_date = self.change_date.beginning_of_month
    end_date = self.change_date.end_of_month

    # 当月休息天数，这个"当月"还是很奇葩，只能认为这段代码运行的那个月!!!
    free_days = VacationRecord.check_free_days(start_date, end_date)
    total_days - free_days
  end
end

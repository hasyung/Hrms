class Api::DinnerPersonSetupsController < ApplicationController
  def load_config
    unless params[:area] && params[:shifts_type]
      render json: {messages: '参数不足'}, status: 400 and return
    end

    # 根据餐费区域和班制筛选
    @config = DinnerPersonSetup.area_config
    @employee_id = params[:employee_id].to_i
    @employee = Employee.find_by(@employee_id)
    @hash = {card_amount: 0, working_fee: 0, breakfast_number: 0, lunch_number: 0, dinner_number: 0}

    if params[:shifts_type] == '空勤'
      # 干部/人员? 配置表是空勤干部和空勤人员
      render json: @hash and return if @employee_id <= 0
      render json: @hash and return if @employee.blank?

      if @employee.category.try(:display_name) == '干部'
        params[:shifts_type] += "干部" # 空勤干部
      else
        params[:shifts_type] += "人员" # 空勤人员
      end

    end

    if DinnerPersonSetup.is_card_area?(params[:area])
      # 饭卡区域
      @record = @config[params[:area] + "@" + params[:shifts_type]]
      if @record
        @hash[:card_amount] = @record["charge_amount"]
        @hash[:breakfast_number] = @record["breakfast_number"]
        @hash[:lunch_number] = @record["lunch_number"]
        @hash[:dinner_number] = @record["dinner_number"]
        @hash[:working_fee] = 0
      end
    else
      @record = @config[params[:area]]
      if @record
        @hash[:card_amount] = 0
        @hash[:breakfast_number] = 0
        @hash[:lunch_number] = 0
        @hash[:dinner_number] = 0
        @hash[:working_fee] = @record[:amount]
        @hash[:unit] = @record[:unit]
      end
    end

    render json: @hash
  end

  def index
    result = parse_query_params!('dinner_person_setup')

    render json: {messages: result[:error]}, status: 400 and return unless result[:error].blank?
    relations, conditions, sorts, page = result.values

    # 餐费设置某些记录是没有实体员工对应的
    @dinner_person_setups = DinnerPersonSetup.joins("LEFT JOIN employees ON employees.id=dinner_person_setups.employee_id").joins("LEFT JOIN departments ON departments.id=employees.department_id").joins("LEFT JOIN employee_positions ON employee_positions.employee_id=employees.id WHERE employee_positions.category='主职'").joins(relations).order(sorts)

    conditions.each do |condition|
      @dinner_person_setups = @dinner_person_setups.where(condition)
    end

    @dinner_person_setups = set_page_meta @dinner_person_setups, page

    @form_data = Welfare.find_by(category: 'dinners').form_data
    @areas = []

    if @form_data.present?
      @form_data[0]['chengdu_head_office'].each do |dict|
        @areas << dict['areas']
      end

      @form_data[1]['chengdu_north_part'].each do |dict|
        @areas << dict['areas']
      end

      @form_data[2]['others'].each do |dict|
        @areas << dict['cities']
      end
    end

    @areas.flatten!.uniq!
  end

  def create
    @dinner_person_setup = DinnerPersonSetup.new(setup_params)

    if @dinner_person_setup.employee.category.try(:display_name) == "干部"
      if @dinner_person_setup.employee.dinner_person_setups.where(area: ["空勤食堂", "北头食堂"]).inject{|sum, x|sum + x.card_amount}.to_f > 150
        render json: {messages: "空勤干部在空勤食堂和北头食堂总额不能超过150"}, status: 400 and return
      end
    end

    @dinner_person_setup.copy_to_form_data

    # 和新进员工的变动逻辑相同
    @dinner_person_setup.create_newbie
    @change_data = @dinner_person_setup.calc_change()

    if @dinner_person_setup.save
      # 因为 8 月份的时候已经把 9 月份的饭卡充值发放，所以需要添加一条工作餐计算记录
      # 因为 8 月份的时候发放的是 7 月份的误餐费，所以不需要增加误餐费的计算记录
      if @dinner_person_setup.is_mealcard_area?
        meal_card_month = Time.new.next_month.strftime("%Y-%m")
        DinnerFee.create(employee_id: @dinner_person_setup.employee_id, employee_no: @dinner_person_setup.employee_no, employee_name: @dinner_person_setup.employee_name, shifts_type: @dinner_person_setup.shifts_type, area: @dinner_person_setup.area, card_number: @dinner_person_setup.card_number, card_amount: @dinner_person_setup.card_number, working_fee: 0, backup_fee: 0, backup_location: nil, month: meal_card_month)

        # 涉及饭卡区域，生成卡变动导出文件
        @filename = "Info#{Time.new.strftime("%Y%m%d")}_#{@dinner_person_setup.area.gsub("食堂", "")}.xls"
        @file_path = "#{Rails.root.to_s}/public/export/tmp/#{@filename}"

        @dinner_person_setup.generate_change_xls("新增", @file_path, @change_data)
        send_file(@file_path, filename: @filename)
        return
      else
        render json: {messages: '创建成功'}
      end
    else
      render json: {messages: @dinner_person_setup.errors.full_messages.join(",")}, status: 400
    end
  end

  def show
    @dinner_person_setup = DinnerPersonSetup.find(params[:id])
  end

  def update
    @dinner_person_setup = DinnerPersonSetup.find(params[:id])

    # 班制是否改变
    @shifts_type_changed = setup_params[:shifts_type] != @dinner_person_setup.shifts_type
    # 餐费区域是否改变
    @area_changed = setup_params[:area] != @dinner_person_setup.area

    @dinner_person_setup.assign_attributes(setup_params)
    @dinner_person_setup.copy_to_form_data
    # 有特殊化，和配置不同
    # 表示餐费个人设置是否被独立修改过?
    @dinner_person_setup.is_config_modified = true

    if @shifts_type_changed && @dinner_person_setup.is_mealcard_area?
      # 饭卡区域的班制调整才有意义，而且饭卡的餐费区域不能调整
      @dinner_person_setup.change_shifts_type
    elsif @area_changed
      # 现金->现金
      @dinner_person_setup.change_cash_location
    end

    @change_data = @dinner_person_setup.calc_change()

    if @dinner_person_setup.save
      @filename = "Info#{Time.new.strftime("%Y%m%d")}_#{@dinner_person_setup.area.gsub("食堂", "")}.xls"
      @file_path = "#{Rails.root.to_s}/public/export/tmp/#{@filename}"

      @dinner_person_setup.generate_change_xls("修改资料", @file_path, @change_data)
      send_file(@file_path, filename: @filename)

      return
    else
      render json: {messages: @dinner_person_setup.errors.full_messages.join(",")}, status: 400
    end
  end

  def batch_delete
    @ids = params[:ids].to_s.split(",")
    DinnerPersonSetup.where(id: @ids).delete_all

    render json: {messages: '批量删除成功'}
  end

  private

  def setup_params
    params.permit(:employee_id, :employee_name, :employee_no, :shifts_type, :area, :card_amount, :working_fee, :breakfast_number, :lunch_number, :dinner_number, :change_date, :is_suspend, :deficit_amount)
  end
end

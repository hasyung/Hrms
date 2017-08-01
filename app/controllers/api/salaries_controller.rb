class Api::SalariesController < ApplicationController
  include ExceptionHandler

  skip_before_action :check_action_register, only: :metadata
  skip_before_action :check_permission, only: :metadata

  def index
    @salaries = Salary.all

    render json: @salaries.inject({}){|hash, salary| hash.merge!({salary.category => salary})}
  end

  def global
    render text: ''
  end

  def update_global
    render text: ''
  end

  def basic
    render text: ''
  end

  def update_basic
    render text: ''
  end

  def performance
    render text: ''
  end

  def update_performance
    render text: ''
  end

  def hours_fee
    render text: ''
  end

  def update_hours_fee
    render text: ''
  end

  def allowance
    render text: ''
  end

  def update_allowance
    render text: ''
  end

  def land_allowance
    render text: ''
  end

  def update_land_allowance
    render text: ''
  end

  def temp
    render text: ''
  end

  def update_temp
    render text: ''
  end

  def cold_subsidy
    render text: ''
  end

  def update_cold_subsidy
    render text: ''
  end

  def metadata
    @salary_setting = Salary.all.inject({}){|hash, salary| hash.merge!({salary.category + '_setting' => salary.form_data})}
    render json: {salary_setting: @salary_setting}
  end

  def update
    permit_form_data

    @old_minimum_wage = Salary.find_by(category: 'global').form_data['minimum_wage']

    if params[:category] == 'land_subsidy'
      @cities = []
      params[:form_data].each do |key, item|
        if item['cities'].present?
          item['cities'].each do |city|
            if @cities.include?(city)
              render json: {messages: "驻地设置 #{city} 有重复"}, status: 400 and return
            else
              @cities << city
            end
          end
        end
      end
    end

    if @salary.save
      if params[:category] == 'global' && @salary.form_data['minimum_wage'] != @old_minimum_wage
        # 需要修复通道为服务B的基础薪酬和绩效薪酬
        service_b_id = CodeTable::Channel.find_by(display_name: '服务B').id
        service_b_ids = []

        Employee.where(channel_id: service_b_id).includes(:salary_person_setup).each do |user|
          service_b_ids << user.salary_person_setup.id if user.salary_person_setup.present?
        end

        base = @salary.form_data['minimum_wage'] || 0
        SalaryPersonSetup.where(id: service_b_ids).update_all("base_money=#{base}, performance_money=base_performance_money-#{base}")
      end

      if !@salary.category.start_with?("service_b_")
        if @salary.category.end_with?("_base")
          @salary.form_data["flags"].each do |grade, config|
            condition = {base_wage: @salary.category, base_flag: grade}
            SalaryPersonSetup.where(condition).update_all(base_money: config['amount'].to_i)
          end
        elsif @salary.category.end_with?("_perf") && @salary.category != "service_tech_perf" # 暂时屏蔽机务service_tech_perf
          @salary.form_data["flags"].each do |grade, config|
            condition = {performance_wage: @salary.category, performance_flag: grade}
            SalaryPersonSetup.where(condition).update_all(performance_money: config['amount'].to_i)
          end
        elsif @salary.category == "flyer_hour"
          @salary.form_data.each do |fly_hour_fee, amount|
            condition = {fly_hour_fee: fly_hour_fee}
            SalaryPersonSetup.where(condition).update_all(fly_hour_money: amount.to_i)
          end
        elsif @salary.category == "fly_attendant_hour"
          @salary.form_data.each do |airline_hour_fee, amount|
            condition = {airline_hour_fee: airline_hour_fee}
            SalaryPersonSetup.where(condition).update_all(airline_hour_money: amount.to_i)
          end
        elsif @salary.category == "air_security_hour"
          @salary.form_data.each do |security_hour_fee, amount|
            condition = {security_hour_fee: security_hour_fee}
            SalaryPersonSetup.where(condition).update_all(security_hour_money: amount.to_i)
          end
        elsif @salary.category == "flyer_science_subsidy"
          @salary.form_data.each do |flyer_science_subsidy, amount|
            condition = {flyer_science_subsidy: flyer_science_subsidy}
            SalaryPersonSetup.where(condition).update_all(flyer_science_money: amount.to_i)
          end
        end
      else
        # 服务B
        @salary.form_data['flags'].each do |grade, config|
          condition = {base_wage: @salary.category, base_flag: grade}
          @amount = config['amount'].to_i
          @perf_money = @amount - @old_minimum_wage
          SalaryPersonSetup.where(condition).update_all(base_money: @old_minimum_wage, performance_money: @perf_money, base_performance_money: @amount)
        end
      end

      render json: {@salary.category => @salary}
    else
      render json: {messages: "参数错误"}, status: 400
    end
  end

  #查询岗位发放标准
  def position_cold_subsidy
    result = parse_query_params!('position')
    render json: {messages: result[:error]}, status: 400 and return unless result[:error].blank?
    relations, conditions, sorts, page = result.values

    @positions = Position.includes(:department).joins(
      "JOIN departments ON positions.department_id = departments.id"
    ).order(
      "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, positions.sort_no"
    ).joins(relations).order(sorts)

    conditions.each do |condition|
      @positions = @positions.where(condition)
    end
    @positions = set_page_meta @positions.uniq, page
  end

  def set_position_cold_subsidy
    @position = Position.find params[:position_id]

    unless @position.update(cold_subsidy_type: params[:cold_subsidy_type])
      render json: {messages: @position.errors.values.flatten.join(",")}, status: 400
    end
  end

  def temperature_amount
    result = parse_query_params!('temperature_amount')
    render json: {messages: result[:error]}, status: 400 and return unless result[:error].blank?
    relations, conditions, sorts, page = result.values

    @positions = Position.includes(:department).joins(
      "JOIN departments ON positions.department_id = departments.id"
    ).order(
      "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, positions.sort_no"
    ).joins(relations).order(sorts)

    conditions.each do |condition|
      @positions = @positions.where(condition)
    end
    @positions = set_page_meta @positions.uniq, page
  end

  def update_temperature_amount
    @position = Position.find_by(id: params[:position_id])
    return render json: {messages: '参数错误'}, status: 400 if @position.blank?

    unless @position.update(temperature_amount: params[:temperature_amount].to_i)
      render json: {messages: @position.errors.values.flatten.join(",")}, status: 400
    end
  end

  def communicate_allowance
    result = parse_query_params!('communicate_allowance')
    render json: {messages: result[:error]}, status: 400 and return unless result[:error].blank?
    relations, conditions, sorts, page = result.values

    @positions = Position.includes(:department).joins(
      "JOIN departments ON positions.department_id = departments.id"
    ).order(
      "departments.d1_sort_no, departments.d2_sort_no, departments.d3_sort_no, positions.sort_no"
    ).joins(relations).order(sorts)

    conditions.each do |condition|
      @positions = @positions.where(condition)
    end
    @positions = set_page_meta @positions.uniq, page
  end

  def update_communicate_allowance
    @position = Position.find_by(id: params[:position_id])
    return render json: {messages: '参数错误'}, status: 400 if @position.blank?

    unless @position.update(communicate_allowance: params[:communicate_allowance].to_i)
      render json: {messages: @position.errors.values.flatten.join(",")}, status: 400
    end
  end

  def communicate_of_duty_rank
    @records = Employee::DutyRank.where("display_name != ?", '无')
  end

  def official_car_of_duty_rank
    @records = Employee::DutyRank.where("display_name != ?", '无')
  end

  def set_communicate_of_duty_rank
    @record = Employee::DutyRank.find params[:id]
    return render json: {messages: '参数错误'}, status: 400 if @record.blank?
    unless @record.update(communicate_allowance: params[:communicate_allowance])
      render json: {messages: '更新错误'}, status: 400
    end
  end

  def set_official_car_of_duty_rank
    @record = Employee::DutyRank.find params[:id]
    return render json: {messages: '参数错误'}, status: 400 if @record.blank?
    unless @record.update(official_car_allowance: params[:official_car_allowance])
      render json: {messages: '更新错误'}, status: 400
    end
  end

  private
  def permit_form_data
    @salary = Salary.find_by(category: params[:category])
    form_data_was = @salary.try(:form_data)
    @salary.assign_attributes(form_data: params[:form_data]) if @salary && params[:form_data].present?

    if params[:category] == 'global'
      @salary.form_data["flight_bonus"].each do |key, value|
        if form_data_was["flight_bonus"] && form_data_was["flight_bonus"][key]
          @salary.form_data["flight_bonus"][key]["sent"] = form_data_was["flight_bonus"][key]["sent"]
        end
      end if @salary.form_data["flight_bonus"]

      @salary.form_data["service_bonus"].each do |key, value|
        if form_data_was["service_bonus"] && form_data_was["service_bonus"][key]
          @salary.form_data["service_bonus"][key]["sent"] = form_data_was["service_bonus"][key]["sent"]
        end
      end if @salary.form_data["service_bonus"]

      @salary.form_data["airline_security_bonus"].each do |key, value|
        if form_data_was["airline_security_bonus"] && form_data_was["airline_security_bonus"][key]
          @salary.form_data["airline_security_bonus"][key]["sent"] = form_data_was["airline_security_bonus"][key]["sent"]
        end
      end if @salary.form_data["airline_security_bonus"]

      @salary.form_data["composite_bonus"].each do |key, value|
        if form_data_was["composite_bonus"] && form_data_was["composite_bonus"][key]
          @salary.form_data["composite_bonus"][key]["sent"] = form_data_was["composite_bonus"][key]["sent"]
        end
      end if @salary.form_data["composite_bonus"]
    end
  end
end

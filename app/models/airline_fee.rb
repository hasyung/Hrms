class AirlineFee < ActiveRecord::Base
  belongs_to :employee

  validates :month, uniqueness: {scope: [:month, :employee_id]}

  class << self
    def split_airline_fee(month)
      #BUG_905
      AirlineFee.includes(:employee => [:salary_person_setup]).where(month: month).each do |item|
        next if item.airline_fee.blank?
        employee = item.employee

        if ["重庆", "昆明"].include? employee.location
          item.update(airline_fee_cash: item.airline_fee)
          next
        end

        if employee.channel.try(:display_name) == "飞行"
            item.airline_fee >= 150 ? item.update(airline_fee_card: 150, airline_fee_cash: item.airline_fee-150) : item.update(airline_fee_cash: item.airline_fee)
            next
        elsif employee.channel.try(:display_name) == "空勤"
          if employee.salary_person_setup.security_hour_fee.present?
            item.airline_fee >= 150 ? item.update(airline_fee_card: 150, airline_fee_cash: item.airline_fee-150) : item.update(airline_fee_cash: item.airline_fee)
            next
          else
            item.airline_fee >= 130 ? item.update(airline_fee_card: 130, airline_fee_cash: item.airline_fee-130) : item.update(airline_fee_cash: item.airline_fee)
            next
          end
        end
      end
    end

    def compute_oversea_food_fee(month)
      is_success, messages = AttendanceSummary.can_calc_salary?(month)
      return [is_success, messages] unless is_success

      @compute_date = Date.parse(month + '-01')

      @remark_hash = LandAllowance.where(month: month).index_by(&:employee_id)

      # 人民币汇率设置
      @dollar_rate = Salary.where(category: 'global').first.form_data['dollar_rate']

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

      t1 = Time.new

      AirlineFee.transaction do
        @calc_values = []

        @channel_id = CodeTable::Channel.where(display_name: "空勤").first.id

        Employee.includes(
          :special_states, :salary_person_setup, :channel, :department,
          :master_positions, :labor_relation
        ).where(
          channel_id: @channel_id
        ).find_in_batches(batch_size: 3000).with_index do |group, batch|
          group.each do |employee|
            @setup = employee.salary_person_setup
            next unless @setup
            next if @setup.try(:is_special_category)

            # FOC派驻表
            @records = @all_records.where(employee_name: employee.name).order(:start_day)
            # 境外hash表
            @date_outland_fee_hash = {}
            @vacation_dates = employee.get_vacation_dates(month)

            hash = {employee_id: employee.id, category: 'oversea_food_fee', month: month}
            calc_step = CalcStep.new(hash)

            @records.each do |record|
              start_date = Date.parse(month + "-#{[record.start_day, @compute_date.end_of_month.day].min}")
              end_date = Date.parse(month + "-#{[record.end_day, @compute_date.end_of_month.day].min}")

              (start_date..end_date).to_a.each do |d|
                if @airline_outland_cities.keys.include?(record.city) && employee.location != record.city
                  rate = @vacation_dates[d].to_i == 0 ? 1 : @vacation_dates[d].to_f
                  @date_outland_fee_hash[d] = @airline_outland_cities[record.city] * rate
                end

                if @vacation_dates[d].present?
                  if @vacation_dates[d] == 0.5
                    calc_step.push_step("日期 #{d} 请假或旷工天数 0.5")
                    @days += 0.5
                  else
                    calc_step.push_step("日期 #{d} 请假或旷工天数 1.0")
                  end
                end
              end
            end

            @total_food_fee = 0
            @date_outland_fee_hash.each do |d, food_fee|
              calc_step.push_step("日期 #{d}，境外餐食补助为 #{food_fee}")
              @total_food_fee += food_fee
            end
            calc_step.final_amount(@total_food_fee)

            record = AirlineFee.where(employee: employee.id, month: month).first
            if record.present?
              record.update(
                oversea_food_fee: @total_food_fee,
                total_fee:        @total_food_fee + record.airline_fee.to_f,
                remark:           @remark_hash[employee.id].try(:remark)
              )
            else
              employee.airline_fees.create(
                employee_name:    employee.name,
                employee_no:      employee.employee_no,
                department_name:  employee.department.full_name,
                position_name:    employee.master_position.name,
                month:            month,
                oversea_food_fee: @total_food_fee,
                total_fee:        @total_food_fee,
                remark:           @remark_hash[employee.id].try(:remark)
              )
            end

            @calc_values << [
              calc_step.employee_id, calc_step.month, calc_step.category,
              calc_step.step_notes, calc_step.amount
            ]
          end
        end

        CalcStep.remove_items('oversea_food_fee', month)
        CalcStep.import(CalcStep::COLUMNS, @calc_values, validate: false)
        @calc_values.clear

        t2 = Time.new
        puts "计算耗费 #{t2 - t1} 秒"

        return true
      end
    end
  end
end

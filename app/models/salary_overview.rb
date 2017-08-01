class SalaryOverview < ActiveRecord::Base
  belongs_to :employee

  validates :month, uniqueness: { scope: [:month, :employee_id] }

  COLUMNS = %w(employee_id month employee_no channel_id employee_name department_name position_name basic 
    keep performance hours_fee security_fee subsidy land_subsidy reward transport_fee bus_fee official_car 
    birth total notes remark)

  def self.compute(month)
    @prev_month = Date.parse(month + '-01').prev_month.strftime("%Y-%m")

    # 正发: 基础、保留、津贴、奖励、交通费
    @basic = @keep = @reward = @transport_fee = @bus_fee = @official_car = 0
    # 倒发: 绩效、小时费、安飞奖、驻站津贴
    @allowance = @performance = @hours_fee = @security_fee = @land_allowance = 0

    @addtion = "total <> 0 OR add_garnishee <> 0"
    @select = "employee_id, total, add_garnishee, month"

    @basic_salaries_hash = BasicSalary.select(@select).where(month: month).where(@addtion).index_by(&:employee_id)
    @keep_salaries_hash = KeepSalary.select(@select).where(month: month).where(@addtion).index_by(&:employee_id)
    @performance_salaries_hash = PerformanceSalary.select(@select).where(month: @prev_month).where(@addtion).index_by(&:employee_id)
    @hours_fees_relation = HoursFee.select(@select + ", hours_fee_category").where(month: @prev_month).where(@addtion)
    @security_fees_hash = SecurityFee.select(@select).where(month: @prev_month).where(@addtion).index_by(&:employee_id)
    @allowances_hash = Allowance.select(@select).where(month: @prev_month).where(@addtion).index_by(&:employee_id)
    @land_allowances_hash = LandAllowance.select(@select).where(month: @prev_month).where(@addtion).index_by(&:employee_id)
    @rewards_hash = Reward.select(@select).where(month: month).where(@addtion).index_by(&:employee_id)
    @transport_fees_hash = TransportFee.select(@select).where(month: month).where(@addtion).index_by(&:employee_id)
    @birth_salaries_hash = BirthSalary.select("employee_id, birth_residue_money, month").where(month: month).index_by(&:employee_id)
    @bus_fees_hash = BusFee.select(@select).where(month: month).where(@addtion).index_by(&:employee_id)
    @official_cars_hash = OfficialCar.select(@select).where(month: month).where(@addtion).index_by(&:employee_id)

    @remark_hash = SalaryOverview.where(month: month).index_by(&:employee_id)

    t1 = Time.new

    TransportFee.transaction do
      @values = []
      @calc_values = []

      Employee.includes(:salary_person_setup, :channel, :department, :master_positions, :labor_relation).find_in_batches(batch_size: 3000).with_index do |group, batch|
        puts "+-----------第 #{batch} 批 -----------+"
        group.each do |employee|
          next unless employee.salary_person_setup.present?

          hash = {employee_id: employee.id, category: 'salary_overview', month: month}
          calc_step = CalcStep.new(hash)

          if employee.is_trainee?
            # 实习生只有实习费，实习的逻辑还不完善
            @total = @basic = 1000
            calc_step.push_step("实习阶段，实习费 #{@basic}")
          elsif employee.salary_person_setup.is_special_category
            # 特殊薪酬人员
          elsif employee.is_service_a?
            # 服务A
          else
            @basic = @basic_salaries_hash[employee.id].try(:total).to_f
            @basic_add_garnishee = @basic_salaries_hash[employee.id].try(:add_garnishee).to_f
            @basic += @basic_add_garnishee
            calc_step.push_step("基础 #{@basic}, 补扣发 #{@basic_add_garnishee}")

            @keep = @keep_salaries_hash[employee.id].try(:total).to_f
            @keep_add_garnishee = @keep_salaries_hash[employee.id].try(:add_garnishee).to_f
            @keep += @keep_add_garnishee
            calc_step.push_step("保留 #{@keep}, 补扣发 #{@keep_add_garnishee}")

            @performance = @performance_salaries_hash[employee.id].try(:total).to_f
            @performance_add_garnishee = @performance_salaries_hash[employee.id].try(:add_garnishee).to_f
            @performance += @performance_add_garnishee
            calc_step.push_step("绩效 #{@performance}, 补扣发 #{@performance_add_garnishee}")

            @hf_records = @hours_fees_relation.where(employee_id: employee.id)
            @hours_fee = @hf_records.map(&:total).inject{|sum=0,x|sum+x.to_f}.to_f

            if @hf_records.size >= 2
              @hours_fee_add_garnishee = @hf_records.where(hours_fee_category: '安全员').first.try(:add_garnishee).to_f
            else
              @hours_fee_add_garnishee = @hf_records.first.try(:add_garnishee).to_f
            end
            @hours_fee += @hours_fee_add_garnishee
            calc_step.push_step("小时费 #{@hours_fee}, 补扣发 #{@hours_fee_add_garnishee}")
            
            @security_fee = @security_fees_hash[employee.id].try(:total).to_f
            @security_fee_add_garnishee = @security_fees_hash[employee.id].try(:add_garnishee).to_f
            @security_fee += @security_fee_add_garnishee
            calc_step.push_step("安飞奖 #{@security_fee}, 补扣发 #{@security_fee_add_garnishee}")

            @allowance = @allowances_hash[employee.id].try(:total).to_f
            @allowance_add_garnishee = @allowances_hash[employee.id].try(:add_garnishee).to_f
            @allowance += @allowance_add_garnishee
            calc_step.push_step("津贴 #{@allowance}, 补扣发 #{@allowance_add_garnishee}")

            @land_allowance = @land_allowances_hash[employee.id].try(:total).to_f
            @land_allowance_add_garnishee = @land_allowances_hash[employee.id].try(:add_garnishee).to_f
            @land_allowance += @land_allowance_add_garnishee
            calc_step.push_step("驻站津贴 #{@land_allowance}, 补扣发 #{@land_allowance_add_garnishee}")

            @transport_fee = @transport_fees_hash[employee.id].try(:total).to_f
            @transport_fee_add_garnishee = @transport_fees_hash[employee.id].try(:add_garnishee).to_f
            @transport_fee += @transport_fee_add_garnishee
            calc_step.push_step("交通费 #{@transport_fee}, 补扣发 #{@transport_fee_add_garnishee}")

            @bus_fee = @bus_fees_hash[employee.id].try(:total).to_f
            @bus_fee_add_garnishee = @bus_fees_hash[employee.id].try(:add_garnishee).to_f
            @bus_fee += @bus_fee_add_garnishee
            calc_step.push_step("班车费 #{@bus_fee}, 补扣发 #{@bus_fee_add_garnishee}")

            @official_car = @official_cars_hash[employee.id].try(:total).to_f
            @official_car_add_garnishee = @official_cars_hash[employee.id].try(:add_garnishee).to_f
            @official_car += @official_car_add_garnishee
            calc_step.push_step("公务车 #{@official_car}, 补扣发 #{@official_car_add_garnishee}")

            @reward = @rewards_hash[employee.id].try(:total).to_f
            @reward_add_garnishee = @rewards_hash[employee.id].try(:add_garnishee).to_f
            @reward += @reward_add_garnishee
            calc_step.push_step("奖励 #{@reward}, 补扣发 #{@reward_add_garnishee}")
          end

          @total = @basic + @keep + @performance + @hours_fee + @security_fee + @allowance + @land_allowance + 
            @transport_fee + @bus_fee + @reward + @official_car
          @birth_residue = @birth_salaries_hash[employee.id].try(:birth_residue_money).to_f
          calc_step.push_step("生育保险抵扣 #{@birth_residue}")
          @total -= @birth_residue
          calc_step.final_amount(@total)

          @notes = ""
          @values << [employee.id, month, employee.employee_no, employee.channel_id, employee.name, 
            employee.department.full_name, employee.master_position.name, @basic, @keep, @performance, @hours_fee, 
            @security_fee, @allowance, @land_allowance, @reward, @transport_fee, @bus_fee, @official_car, @birth_residue, @total, 
            @notes, @remark_hash[employee.id].try(:remark)]
          @calc_values << [calc_step.employee_id, calc_step.month, calc_step.category, calc_step.step_notes, calc_step.amount]
        end
      end

      # 先全部删除计算记录
      SalaryOverview.where(month: month).delete_all
      CalcStep.remove_items('salary_overview', month)

      CalcStep.import(CalcStep::COLUMNS, @calc_values, validate: false)
      SalaryOverview.import(COLUMNS, @values, validate: false)

      @calc_values.clear
      @values.clear
    end

    t2 = Time.new
    puts "计算耗费 #{t2 - t1} 秒"

    return true
  end
end

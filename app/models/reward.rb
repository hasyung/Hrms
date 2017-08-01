class Reward < ActiveRecord::Base
  belongs_to :employee

  validates :month, uniqueness: { scope: [:month, :employee_id] }

  IMPORTOR_TYPE = {
    "航班正常奖"               => :import_flight_bonus,
    "月度服务质量奖"           => :import_service_bonus,
    "日常航空安全奖"           => :import_airline_security_bonus,
    "社会治安综合治理奖"       => :import_composite_bonus,
    "电子航意险代理提成奖"     => :import_insurance_proxy,
    "客舱升舱提成奖"           => :import_cabin_grow_up,
    "全员促销奖"               => :import_full_sale_promotion,
    "四川航空报稿费"           => :import_article_fee,
    "无差错飞行中队奖"         => :import_all_right_fly,
    "年度社会治安综合治理奖"   => :import_year_composite_bonus,
    "运兵先进奖"               => :import_move_perfect,
    "航空安全特殊贡献奖"       => :import_security_special,
    "部门安全管理目标承包奖"   => :import_dep_security_undertake,
    "飞行安全星级奖"           => :import_fly_star,
    "年度无差错机务维修中队奖" => :import_year_all_right_fly,
    "客运目标责任书季度奖"     => :import_passenger_quarter_fee,
    "货运目标责任书季度奖"     => :import_freight_quality_fee,
    "收益奖励金"               => :import_earnings_fee,
    "内部奖惩"               => :import_off_budget_fee,
    "节油奖"                   => :import_save_oil_fee,
    "品牌质量考核奖"           => :import_brand_quality_fee,
    "其他事件性奖惩"               => :import_cash_fine_fee,
  }

  COLUMNS = %w(
  employee_id month employee_no channel_id employee_name department_name
  position_name flight_bonus service_bonus airline_security_bonus
  composite_bonus insurance_proxy cabin_grow_up full_sale_promotion
  article_fee all_right_fly year_composite_bonus move_perfect security_special
  dep_security_undertake fly_star year_all_right_fly
  passenger_quarter_fee freight_quality_fee earnings_fee off_budget_fee total
  add_garnishee remark save_oil_fee brand_quality_fee cash_fine_fee salary_set_book
  )

  SKIP_DEPARTMENT_SALARY_CHECK_IMPORT_TYPE = [
    :import_off_budget_fee, :import_save_oil_fee
  ]

  class << self
    def sum_dep_salaries(year)
      reward_type = [
        :flight_bonus, :service_bonus, :airline_security_bonus, :composite_bonus,
        :insurance_proxy, :cabin_grow_up, :full_sale_promotion, :article_fee,
        :all_right_fly, :year_composite_bonus, :move_perfect, :security_special,
        :dep_security_undertake, :fly_star, :year_all_right_fly,
        :passenger_quarter_fee, :freight_quality_fee, :earnings_fee, :brand_quality_fee
      ]
      reward_hash = reward_type.inject({}) do |hash, item|
        hash[item] = DepartmentSalary.where("month like '%#{year}%'").sum(item)
        hash
      end
      config = Salary.find_by(category: 'global')
      reward_type.each do |item|
        if config.form_data[item].present?
          config.form_data[item][year.to_s]['sent'] = reward_hash[item].to_f
        else
          logger.error "-----------reward sum_dep_salaries error -----"
          logger.error "#{item}"
        end
      end
      config.save
    end

    def compute(month)
      is_success, messages = AttendanceSummary.can_calc_salary?(month)
      return [is_success, messages] unless is_success

      # 先全部删除计算记录
      @remark_hash = Reward.where(month: month).index_by(&:employee_id)

      @records = RewardRecord.where(month: month).index_by(&:employee_name)

      t1 = Time.new

      Reward.sum_dep_salaries(month.split("-")[0])

      KeepSalary.transaction do
        @values = []
        @calc_values = []

        Employee.includes(:salary_person_setup, :channel, :department, :master_positions, :labor_relation).find_in_batches(batch_size: 3000).with_index do |group, batch|
          logger.error "+-----------第 #{batch} 批 -----------+"
          group.each do |employee|
            next unless employee.salary_person_setup

            # raise "#{employee.name} 缺少薪酬设置" if !employee.salary_person_setup

            hash = {employee_id: employee.id, category: 'reward', month: month}
            calc_step = CalcStep.new(hash)

            record = @records[employee.name]

            if record.present?
              # 航班正常奖
              @flight_bonus = record.flight_bonus.to_f
              calc_step.push_step("航班正常奖 #{@flight_bonus}")

              # 月度服务质量奖
              @service_bonus = record.service_bonus.to_f
              calc_step.push_step("月度服务质量奖 #{@service_bonus}")

              # 品牌质量考核奖
              @brand_quality_fee = record.brand_quality_fee.to_f
              calc_step.push_step("品牌质量考核奖 #{@brand_quality_fee}")

              # 日常航空安全奖
              @airline_security_bonus = record.airline_security_bonus.to_f
              calc_step.push_step("日常航空安全奖 #{@airline_security_bonus}")

              # 社会治安综合治理奖
              @composite_bonus = record.composite_bonus.to_f
              calc_step.push_step("社会治安综合治理奖 #{@composite_bonus}")

              # 电子航意险代理提成奖
              @insurance_proxy = record.insurance_proxy.to_f
              calc_step.push_step("电子航意险代理提成奖 #{@insurance_proxy}")

              # 客舱升舱提成奖
              @cabin_grow_up = record.cabin_grow_up.to_f
              calc_step.push_step("客舱升舱提成奖 #{@cabin_grow_up}")

              # 全员促销奖
              @full_sale_promotion = record.full_sale_promotion.to_f
              calc_step.push_step("全员促销奖 #{@full_sale_promotion}")

              # 四川航空报稿费
              @article_fee = record.article_fee.to_f
              calc_step.push_step("四川航空报稿费 #{@article_fee}")

              # 无差错飞行中队奖
              @all_right_fly = record.all_right_fly.to_f
              calc_step.push_step("无差错飞行中队奖 #{@all_right_fly}")

              # 年度社会治安综合治理奖
              @year_composite_bonus = record.year_composite_bonus.to_f
              calc_step.push_step("年度社会治安综合治理奖 #{@year_composite_bonus}")

              # 运兵先进奖
              @move_perfect = record.move_perfect.to_f
              calc_step.push_step("运兵先进奖 #{@move_perfect}")

              # 航空安全特殊贡献奖
              @security_special = record.security_special.to_f
              calc_step.push_step("航空安全特殊贡献奖 #{@security_special}")

              # 部门安全管理目标承包奖
              @dep_security_undertake = record.dep_security_undertake.to_f
              calc_step.push_step("部门安全管理目标承包奖 #{@dep_security_undertake}")

              # 飞行安全星级奖
              @fly_star = record.fly_star.to_f
              calc_step.push_step("飞行安全星级奖 #{@fly_star}")

              # 年度无差错机务维修中队奖
              @year_all_right_fly= record.year_all_right_fly.to_f
              calc_step.push_step("年度无差错机务维修中队奖 #{@year_all_right_fly}")

              # 客运目标责任书季度奖励
              @passenger_quarter_fee = record.passenger_quarter_fee.to_f
              calc_step.push_step("客运目标责任书季度奖励 #{@passenger_quarter_fee}")

              # 货运目标责任书季度奖
              @freight_quality_fee = record.freight_quality_fee.to_f
              calc_step.push_step("货运目标责任书季度奖 #{@passenger_quarter_fee}")

              # 收益奖励金
              @earnings_fee = record.earnings_fee.to_f
              calc_step.push_step("收益奖励金 #{@earnings_fee}")

              # 预算外奖励
              @off_budget_fee = record.off_budget_fee.to_f
              calc_step.push_step("预算外奖励 #{@off_budget_fee}")

              # 节油奖
              @save_oil_fee = record.save_oil_fee.to_f
              calc_step.push_step("节油奖 #{@save_oil_fee}")

              # 经济型扣罚
              @cash_fine_fee = record.cash_fine_fee.to_f
              calc_step.push_step("经济型扣罚 #{@cash_fine_fee}")

              @total = @flight_bonus + @service_bonus + @airline_security_bonus + @composite_bonus + @insurance_proxy + @cabin_grow_up + @full_sale_promotion + @article_fee + @all_right_fly + @year_composite_bonus + @move_perfect + @security_special + @dep_security_undertake + @fly_star + @year_all_right_fly + @passenger_quarter_fee + @freight_quality_fee + @earnings_fee + @off_budget_fee + @save_oil_fee + @brand_quality_fee + @cash_fine_fee
            else
              @flight_bonus = @service_bonus = @airline_security_bonus = @composite_bonus = @insurance_proxy = @cabin_grow_up = @full_sale_promotion = @article_fee = @all_right_fly = @year_composite_bonus = @move_perfect = @security_special = @dep_security_undertake = @fly_star = @year_all_right_fly = @passenger_quarter_fee = @freight_quality_fee = @earnings_fee = @off_budget_fee = @save_oil_fee = @brand_quality_fee = @cash_fine_fee = 0
              @total = 0
            end

            calc_step.push_step("奖金总和 #{@total}")
            calc_step.final_amount(@total)

            @values << [
              employee.id, month, employee.employee_no, employee.channel_id,
              employee.name, employee.department.full_name,
              employee.master_position.name, @flight_bonus, @service_bonus,
              @airline_security_bonus, @composite_bonus, @insurance_proxy,
              @cabin_grow_up, @full_sale_promotion, @article_fee,
              @all_right_fly, @year_composite_bonus, @move_perfect,
              @security_special, @dep_security_undertake, @fly_star,
              @year_all_right_fly, @passenger_quarter_fee, @freight_quality_fee,
              @earnings_fee, @off_budget_fee, @total,
              @remark_hash[employee.id].try(:add_garnishee).to_f,
              @remark_hash[employee.id].try(:remark),
              @save_oil_fee,
              @brand_quality_fee,
              @cash_fine_fee,
              employee.salary_set_book
            ]

            @calc_values << [
              calc_step.employee_id, calc_step.month, calc_step.category,
              calc_step.step_notes, calc_step.amount
            ]
          end
        end

        Reward.where(month: month).delete_all
        CalcStep.remove_items('reward', month)

        CalcStep.import(CalcStep::COLUMNS, @calc_values, validate: false)
        Reward.import(COLUMNS, @values, validate: false)

        @calc_values.clear
        @values.clear
      end

      t2 = Time.new
      logger.error "计算耗费 #{t2 - t1} 秒"

      return true
    end
  end
end

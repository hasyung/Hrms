class BirthSalary < ActiveRecord::Base
  belongs_to :employee

  validates :month, uniqueness: { scope: [:month, :employee_id] }

  COLUMNS = %w(employee_id employee_no employee_name department_name position_name channel_id 
    basic_salary working_years_salary keep_salary performance_salary hours_fee security_fee budget_reward 
    transport_fee bus_fee temp_allowance residue_money birth_residue_money after_residue_money 
    remark notes month)

  class << self
    def compute(month)
      PerformanceSalary.transaction do
        values, calc_values, allowance_values, temp_values = [], [], [], []

        is_success, messages = AttendanceSummary.can_calc_salary?(month)
        return [is_success, messages] unless is_success

        current_allowances = BirthAllowance.joins(:employee).where(month: month)
        current_allowances.includes(employee: :birth_salaries).each do |allowance|
          birth_salary = allowance.employee.birth_salaries.select{|s| s.month == month}.first
          temp_values << [allowance.employee_id, allowance.employee_no, allowance.employee_name, 
            allowance.department_name, allowance.position_name, allowance.sent_date, allowance.sent_amount, 
            allowance.deduct_amount.to_f - birth_salary.try(:birth_residue_money).to_f, '']
        end if current_allowances.present?

        current_allowances.delete_all
        BirthAllowance.import(BirthAllowance::COLUMNS, temp_values, validate: false)

        salaries_hash = BirthSalary.where(month: month).index_by(&:employee_id)
        birth_allowances = BirthAllowance.joins(:employee).where("sent_amount - deduct_amount > 0")

        birth_allowances.includes(employee: [:basic_salaries, :keep_salaries, :performance_salaries, :hours_fees, 
          :allowances, :rewards, :transport_fees, :department, :master_positions, :annuities, :social_records, 
          :bus_fees]).each do |salary|
          calc_step = CalcStep.new employee_id: salary.employee_id, month: month, category: 'birth_salary'
          prev_month = Date.parse(month + "-01").prev_month.strftime("%Y-%m")

          basic = salary.employee.basic_salaries.select{|s| s.month == month}.first
          keep = salary.employee.keep_salaries.select{|s| s.month == month}.first
          hours = salary.employee.hours_fees.select{|s| s.month == prev_month}.first
          security = salary.employee.security_fees.select{|s| s.month == prev_month}.first
          perf = salary.employee.performance_salaries.select{|s| s.month == prev_month}.first
          reward = salary.employee.rewards.select{|s| s.month == month}.first
          transport = salary.employee.transport_fees.select{|s| s.month == month}.first
          bus = salary.employee.bus_fees.select{|s| s.month == month}.first

          basic_salary = basic.try(:position_salary).to_f
          working_years_salary = basic.try(:working_years_salary).to_f
          keep_salary = keep.try(:total).to_f
          performance_salary = perf.try(:total).to_f
          hours_fee = hours.try(:total).to_f
          security_fee = security.try(:total).to_f
          budget_reward = reward.try(:network_connect).to_f + reward.try(:quarter_fee).to_f + reward.try(:earnings_fee).to_f
          transport_fee = transport.try(:total).to_f
          temp_allowance = salary.employee.allowances.select{|s| s.month == prev_month}.first.try(:temp).to_f
          t_personage = salary.employee.social_records.select{|s| s.compute_month == prev_month}.first.try(:t_personage).to_f
          annuity = salary.employee.annuities.select{|s| s.cal_date == prev_month}.first.try(:personal_payment).to_f
          residue_money = salary.sent_amount - salary.deduct_amount
          bus_fee = bus.try(:fee).to_f

          can_residue_money = basic_salary + working_years_salary + basic.try(:add_garnishee).to_f + keep_salary + 
            keep.try(:add_garnishee).to_f + hours_fee + hours.try(:add_garnishee).to_f + 
            security_fee + security.try(:add_garnishee).to_f + performance_salary + 
            perf.try(:add_garnishee).to_f + budget_reward + transport_fee + transport.try(:add_garnishee).to_f + 
            bus.try(:fee).to_f + bus.try(:add_garnishee).to_f + temp_allowance - t_personage - 
            salary.employee.personal_reserved_funds.to_f - annuity

          calc_step.push_step("基本工资(#{basic_salary}) + 工龄工资(#{working_years_salary}) + 基本工资补扣发" + 
            "(#{basic.try(:add_garnishee).to_f}) + 保留工资(#{keep_salary}) + 保留工资补扣发(#{keep.try(:add_garnishee).to_f}) " + 
            "+ 小时费(#{hours_fee}) + 小时费补扣发(#{hours.try(:add_garnishee).to_f}) + 安飞奖(#{security_fee}) " + 
            "+ 安飞奖补扣发(#{security.try(:add_garnishee).to_f}) + 考核性收入(#{performance_salary})" + 
            " + 考核性收入补扣发(#{perf.try(:add_garnishee).to_f}) + 收支目标考核奖(#{budget_reward}) + 交通费(#{transport_fee})" + 
            " + 交通费补扣发(#{transport.try(:add_garnishee).to_f}) + 班车费(#{bus_fee}) + 班车费代扣" + 
            "(#{bus.try(:add_garnishee).to_f}) + 高温津贴(#{temp_allowance}) - 社保代扣(#{t_personage})" + 
            " - 公积金个人(#{salary.employee.personal_reserved_funds.to_f}) - 企业年金个人(#{annuity}) = 当月可冲抵额度" + 
            "(#{can_residue_money})")

          deduct_amount = salary.deduct_amount
          birth_residue_money = 0
          after_residue_money = residue_money
          if can_residue_money > 800
            if residue_money - (can_residue_money - 800) > 0
              deduct_amount += can_residue_money - 800
              birth_residue_money = can_residue_money - 800
              after_residue_money = residue_money - (can_residue_money - 800)
            else
              deduct_amount = salary.sent_amount
              birth_residue_money = residue_money
              after_residue_money = 0
            end
          end
          calc_step.push_step("上期生育保险剩余抵扣金额为: #{residue_money}, 当期生育保险实际冲抵金额为: #{birth_residue_money}," + 
            " 当期生育保险抵扣后剩余金额为: #{after_residue_money}")

          allowance_values << [salary.employee_id, salary.employee_no, salary.employee_name, 
            salary.department_name, salary.position_name, salary.sent_date, salary.sent_amount, 
            deduct_amount, month]

          values << [salary.employee.id, salary.employee.employee_no, salary.employee.name, 
            salary.employee.department.full_name, salary.employee.master_positions.first.name, 
            salary.employee.channel_id, basic_salary, working_years_salary, keep_salary, performance_salary, 
            hours_fee, security_fee, budget_reward, transport_fee, bus_fee, temp_allowance, residue_money, birth_residue_money, 
            after_residue_money, salaries_hash[salary.employee_id].try(:remark), '', month]

          calc_values << [calc_step.employee_id, calc_step.month, calc_step.category, calc_step.step_notes.to_a, birth_residue_money]
        end

        CalcStep.where("month='#{month}' and category='birth_salary'").delete_all
        birth_allowances.delete_all
        BirthSalary.where(month: month).delete_all

        CalcStep.import(CalcStep::COLUMNS, calc_values, validate: false)
        BirthAllowance.import(BirthAllowance::COLUMNS, allowance_values, validate: false)
        BirthSalary.import(BirthSalary::COLUMNS, values, validate: false)
      end
    end

  end
end

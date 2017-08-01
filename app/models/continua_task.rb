class ContinuaTask
  def self.send_continua_contract
    #合同到期续签提醒
    Contract.where(end_date: Date.today + 40.days, original: true).find_each do |item|
      notifier_ids = Employee.where(
        "special_ca like '%- contracts_import%' or special_ca like '%- contracts_update%' or special_ca like '%- contracts_create%'"
      ).pluck(:id).uniq

      notifier_ids.each do |employee_id|
        Notification.send_user_message(employee_id, 'contract', "员工#{item.employee_name}(工号#{item.employee_no})的合同将于40天后到期，请关注。")
      end
    end
  end

  def self.send_continua_agreement
    #协议到期续签提醒
    Agreement.where(end_date: Date.today + 40.days).find_each do |item|
      notifier_ids = Employee.where(
        "special_ca like '%- agreements_create%' or special_ca like '%- agreements_update%'"
      ).pluck(:id).uniq

      notifier_ids.each do |employee_id|
        Notification.send_user_message(employee_id, 'agreement', "员工#{item.employee_name}(工号#{item.employee_no})的协议将于40天后到期，请关注。")
      end
    end
  end

  def self.init_vacation
    VacationRecord.check_fix_update
  end

  def self.add_working_years_salary_every_year
    if Date.current.strftime("%m-%d") == '01-15'
      setups = SalaryPersonSetup.joins(employee: [:labor_relation, :channel]).where("code_table_channels.display_name not in (?) 
        and (code_table_channels.display_name = '空勤' or employee_labor_relations.display_name in (?))", %w(服务A 服务B), %w(合同 合同制))
      setups.each do |setup|
        setup.update(working_years_salary: setup.working_years_salary.to_f + 40)
      end
    elsif Date.current.strftime("%m-%d") == '02-15'
      setups = SalaryPersonSetup.joins(employee: [:labor_relation, :channel]).where("code_table_channels.display_name not in (?) 
        and employee_labor_relations.display_name not in (?)", %w(服务A 服务B 空勤), %w(合同 合同制))
      setups.each do |setup|
        setup.update(working_years_salary: setup.working_years_salary.to_f + 40)
      end
    end
  end

  def perform
    ContinuaTask.send_continua_contract
    ContinuaTask.send_continua_agreement
    ContinuaTask.init_vacation
    ContinuaTask.add_working_years_salary_every_year
  end
end
